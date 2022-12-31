# frozen_string_literal: true

require 'rumale/base/classifier'
require 'rumale/utils'
require 'rumale/validation'
require 'rumale/neural_network/base_mlp'

module Rumale
  module NeuralNetwork
    # MLPClassifier is a class that implements classifier based on multi-layer perceptron.
    # MLPClassifier use ReLu as the activation function and Adam as the optimization method
    # and softmax cross entropy as the loss function.
    #
    # @example
    #   require 'rumale/neural_network/mlp_classifier'
    #
    #   estimator = Rumale::NeuralNetwork::MLPClassifier.new(hidden_units: [100, 100], dropout_rate: 0.3)
    #   estimator.fit(training_samples, traininig_labels)
    #   results = estimator.predict(testing_samples)
    class MLPClassifier < BaseMLP
      include ::Rumale::Base::Classifier

      # Return the network.
      # @return [Rumale::NeuralNetwork::Model::Sequential]
      attr_reader :network

      # Return the class labels.
      # @return [Numo::Int32] (size: n_classes)
      attr_reader :classes

      # Return the number of iterations run for optimization
      # @return [Integer]
      attr_reader :n_iter

      # Return the random generator.
      # @return [Random]
      attr_reader :rng

      # Create a new classifier with multi-layer preceptron.
      #
      # @param hidden_units [Array] The number of units in the i-th hidden layer.
      # @param dropout_rate [Float] The rate of the units to drop.
      # @param learning_rate [Float] The initial value of learning rate in Adam optimizer.
      # @param decay1 [Float] The smoothing parameter for the first moment in Adam optimizer.
      # @param decay2 [Float] The smoothing parameter for the second moment in Adam optimizer.
      # @param max_iter [Integer] The maximum number of epochs that indicates
      #   how many times the whole data is given to the training process.
      # @param batch_size [Intger] The size of the mini batches.
      # @param tol [Float] The tolerance of loss for terminating optimization.
      # @param verbose [Boolean] The flag indicating whether to output loss during iteration.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      def initialize(hidden_units: [128, 128], dropout_rate: 0.4, learning_rate: 0.001, decay1: 0.9, decay2: 0.999,
                     max_iter: 200, batch_size: 50, tol: 1e-4, verbose: false, random_seed: nil)
        super
      end

      # Fit the model with given training data.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Numo::Int32] (shape: [n_samples]) The labels to be used for fitting the model.
      # @return [MLPClassifier] The learned classifier itself.
      def fit(x, y)
        x = ::Rumale::Validation.check_convert_sample_array(x)
        y = ::Rumale::Validation.check_convert_label_array(y)
        ::Rumale::Validation.check_sample_size(x, y)

        @classes = Numo::Int32[*y.to_a.uniq.sort]
        n_labels = @classes.size
        n_features = x.shape[1]
        sub_rng = @rng.dup

        loss = ::Rumale::NeuralNetwork::Loss::SoftmaxCrossEntropy.new
        @network = buld_network(n_features, n_labels, sub_rng)
        @network = train(x, one_hot_encode(y), @network, loss, sub_rng)
        @network.delete_dropout

        self
      end

      # Predict class labels for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the labels.
      # @return [Numo::Int32] (shape: [n_samples]) Predicted class label per sample.
      def predict(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        n_samples = x.shape[0]
        decision_values = predict_proba(x)
        predicted = Array.new(n_samples) { |n| @classes[decision_values[n, true].max_index] }
        Numo::Int32.asarray(predicted)
      end

      # Predict probability for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the probailities.
      # @return [Numo::DFloat] (shape: [n_samples, n_classes]) Predicted probability of each class per sample.
      def predict_proba(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        out, = @network.forward(x)
        softmax(out)
      end

      private

      def one_hot_encode(y)
        ::Rumale::Utils.binarize_labels(y)
      end

      def softmax(x)
        clip = x.max(-1).expand_dims(-1)
        exp_x = Numo::NMath.exp(x - clip)
        exp_x / exp_x.sum(axis: -1).expand_dims(-1)
      end
    end
  end
end
