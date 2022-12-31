# frozen_string_literal: true

require 'rumale/utils'
require 'rumale/validation'
require 'rumale/base/estimator'
require 'rumale/base/classifier'
require 'rumale/tree/decision_tree_classifier'
require 'rumale/ensemble/value'

module Rumale
  module Ensemble
    # AdaBoostClassifier is a class that implements AdaBoost (SAMME.R) for classification.
    # This class uses decision tree for a weak learner.
    #
    # @example
    #   require 'rumale/ensemble/ada_boost_classifier'
    #
    #   estimator =
    #     Rumale::Ensemble::AdaBoostClassifier.new(
    #       n_estimators: 10, criterion: 'gini', max_depth: 3, max_leaf_nodes: 10, min_samples_leaf: 5, random_seed: 1)
    #   estimator.fit(training_samples, traininig_labels)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # - Zhu, J., Rosset, S., Zou, H., and Hashie, T., "Multi-class AdaBoost," Technical Report No. 430, Department of Statistics, University of Michigan, 2005.
    class AdaBoostClassifier < ::Rumale::Base::Estimator
      include ::Rumale::Base::Classifier

      # Return the set of estimators.
      # @return [Array<DecisionTreeClassifier>]
      attr_reader :estimators

      # Return the class labels.
      # @return [Numo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the importance for each feature.
      # @return [Numo::DFloat] (size: n_features)
      attr_reader :feature_importances

      # Return the random generator for random selection of feature index.
      # @return [Random]
      attr_reader :rng

      # Create a new classifier with AdaBoost.
      #
      # @param n_estimators [Integer] The numeber of decision trees for contructing AdaBoost classifier.
      # @param criterion [String] The function to evalue spliting point. Supported criteria are 'gini' and 'entropy'.
      # @param max_depth [Integer] The maximum depth of the tree.
      #   If nil is given, decision tree grows without concern for depth.
      # @param max_leaf_nodes [Integer] The maximum number of leaves on decision tree.
      #   If nil is given, number of leaves is not limited.
      # @param min_samples_leaf [Integer] The minimum number of samples at a leaf node.
      # @param max_features [Integer] The number of features to consider when searching optimal split point.
      #   If nil is given, split process considers all features.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      #   It is used to randomly determine the order of features when deciding spliting point.
      def initialize(n_estimators: 50,
                     criterion: 'gini', max_depth: nil, max_leaf_nodes: nil, min_samples_leaf: 1,
                     max_features: nil, random_seed: nil)
        super()
        @params = {
          n_estimators: n_estimators,
          criterion: criterion,
          max_depth: max_depth,
          max_leaf_nodes: max_leaf_nodes,
          min_samples_leaf: min_samples_leaf,
          max_features: max_features,
          random_seed: random_seed || srand
        }
        @rng = Random.new(@params[:random_seed])
      end

      # Fit the model with given training data.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Numo::Int32] (shape: [n_samples]) The labels to be used for fitting the model.
      # @return [AdaBoostClassifier] The learned classifier itself.
      def fit(x, y) # rubocop:disable Metrics/AbcSize
        x = ::Rumale::Validation.check_convert_sample_array(x)
        y = ::Rumale::Validation.check_convert_label_array(y)
        ::Rumale::Validation.check_sample_size(x, y)

        ## Initialize some variables.
        n_samples, n_features = x.shape
        @estimators = []
        @feature_importances = Numo::DFloat.zeros(n_features)
        @params[:max_features] = n_features unless @params[:max_features].is_a?(Integer)
        @params[:max_features] = [[1, @params[:max_features]].max, n_features].min
        @classes = Numo::Int32.asarray(y.to_a.uniq.sort)
        n_classes = @classes.shape[0]
        sub_rng = @rng.dup
        ## Boosting.
        classes_arr = @classes.to_a
        y_codes = Numo::DFloat.zeros(n_samples, n_classes) - 1.fdiv(n_classes - 1)
        n_samples.times { |n| y_codes[n, classes_arr.index(y[n])] = 1.0 }
        observation_weights = Numo::DFloat.zeros(n_samples) + 1.fdiv(n_samples)
        @params[:n_estimators].times do |_t|
          # Fit classfier.
          ids = ::Rumale::Utils.choice_ids(n_samples, observation_weights, sub_rng)
          break if y[ids].to_a.uniq.size != n_classes

          tree = ::Rumale::Tree::DecisionTreeClassifier.new(
            criterion: @params[:criterion], max_depth: @params[:max_depth],
            max_leaf_nodes: @params[:max_leaf_nodes], min_samples_leaf: @params[:min_samples_leaf],
            max_features: @params[:max_features], random_seed: sub_rng.rand(::Rumale::Ensemble::Value::SEED_BASE)
          )
          tree.fit(x[ids, true], y[ids])
          # Calculate estimator error.
          proba = tree.predict_proba(x).clip(1.0e-15, nil)
          pred = Numo::Int32.asarray(Array.new(n_samples) { |n| @classes[proba[n, true].max_index] })
          inds = pred.ne(y)
          error = (observation_weights * inds).sum / observation_weights.sum
          # Store model.
          @estimators.push(tree)
          @feature_importances += tree.feature_importances
          break if error.zero?

          # Update observation weights.
          log_proba = Numo::NMath.log(proba)
          observation_weights *= Numo::NMath.exp(-1.0 * (n_classes - 1).fdiv(n_classes) * (y_codes * log_proba).sum(axis: 1))
          observation_weights = observation_weights.clip(1.0e-15, nil)
          sum_observation_weights = observation_weights.sum
          break if sum_observation_weights.zero?

          observation_weights /= sum_observation_weights
        end
        @feature_importances /= @feature_importances.sum
        self
      end

      # Calculate confidence scores for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to compute the scores.
      # @return [Numo::DFloat] (shape: [n_samples, n_classes]) Confidence score per sample.
      def decision_function(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        n_samples, = x.shape
        n_classes = @classes.size
        sum_probs = Numo::DFloat.zeros(n_samples, n_classes)
        @estimators.each do |tree|
          log_proba = Numo::NMath.log(tree.predict_proba(x).clip(1.0e-15, nil))
          sum_probs += (n_classes - 1) * (log_proba - 1.fdiv(n_classes) * Numo::DFloat[log_proba.sum(axis: 1)].transpose)
        end
        sum_probs /= @estimators.size
      end

      # Predict class labels for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Numo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        n_samples, = x.shape
        probs = decision_function(x)
        Numo::Int32.asarray(Array.new(n_samples) { |n| @classes[probs[n, true].max_index] })
      end

      # Predict probability for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      # @return [Numo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        n_classes = @classes.size
        probs = Numo::NMath.exp(1.fdiv(n_classes - 1) * decision_function(x))
        sum_probs = probs.sum(axis: 1)
        probs /= Numo::DFloat[sum_probs].transpose
        probs
      end
    end
  end
end
