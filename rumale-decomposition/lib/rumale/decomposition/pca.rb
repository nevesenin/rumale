# frozen_string_literal: true

require 'rumale/base/estimator'
require 'rumale/base/transformer'
require 'rumale/utils'
require 'rumale/validation'

module Rumale
  # Module for matrix decomposition algorithms.
  module Decomposition
    # PCA is a class that implements Principal Component Analysis.
    #
    # @example
    #   require 'rumale/decomposition/pca'
    #
    #   decomposer = Rumale::Decomposition::PCA.new(n_components: 2, solver: 'fpt')
    #   representaion = decomposer.fit_transform(samples)
    #
    #   # If Numo::Linalg is installed, you can specify 'evd' for the solver option.
    #   require 'numo/linalg/autoloader'
    #   require 'rumale/decomposition/pca'
    #
    #   decomposer = Rumale::Decomposition::PCA.new(n_components: 2, solver: 'evd')
    #   representaion = decomposer.fit_transform(samples)
    #
    #   # If Numo::Linalg is loaded and the solver option is not given,
    #   # the solver option is choosen 'evd' automatically.
    #   decomposer = Rumale::Decomposition::PCA.new(n_components: 2)
    #   representaion = decomposer.fit_transform(samples)
    #
    # *Reference*
    # - Sharma, A., and Paliwal, K K., "Fast principal component analysis using fixed-point algorithm," Pattern Recognition Letters, 28, pp. 1151--1155, 2007.
    class PCA < ::Rumale::Base::Estimator
      include ::Rumale::Base::Transformer

      # Returns the principal components.
      # @return [Numo::DFloat] (shape: [n_components, n_features])
      attr_reader :components

      # Returns the mean vector.
      # @return [Numo::DFloat] (shape: [n_features])
      attr_reader :mean

      # Return the random generator.
      # @return [Random]
      attr_reader :rng

      # Create a new transformer with PCA.
      #
      # @param n_components [Integer] The number of principal components.
      # @param solver [String] The algorithm for the optimization ('auto', 'fpt' or 'evd').
      #   'auto' chooses the 'evd' solver if Numo::Linalg is loaded. Otherwise, it chooses the 'fpt' solver.
      #   'fpt' uses the fixed-point algorithm.
      #   'evd' performs eigen value decomposition of the covariance matrix of samples.
      # @param max_iter [Integer] The maximum number of iterations. If solver = 'evd', this parameter is ignored.
      # @param tol [Float] The tolerance of termination criterion. If solver = 'evd', this parameter is ignored.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      def initialize(n_components: 2, solver: 'auto', max_iter: 100, tol: 1.0e-4, random_seed: nil)
        super()
        @params = {
          n_components: n_components,
          solver: 'fpt',
          max_iter: max_iter,
          tol: tol,
          random_seed: (random_seed || srand)
        }
        @params[:solver] = 'evd' if (solver == 'auto' && enable_linalg?(warning: false)) || solver == 'evd'
        @rng = Random.new(@params[:random_seed])
      end

      # Fit the model with given training data.
      #
      # @overload fit(x) -> PCA
      #   @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      #   @return [PCA] The learned transformer itself.
      def fit(x, _y = nil)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        # initialize some variables.
        @components = nil
        n_samples, n_features = x.shape
        sub_rng = @rng.dup
        # centering.
        @mean = x.mean(0)
        centered_x = x - @mean
        # optimization.
        covariance_mat = centered_x.transpose.dot(centered_x) / (n_samples - 1)
        if @params[:solver] == 'evd' && enable_linalg?
          _, evecs = Numo::Linalg.eigh(covariance_mat, vals_range: (n_features - @params[:n_components])...n_features)
          comps = evecs.reverse(1).transpose
          @components = @params[:n_components] == 1 ? comps[0, true].dup : comps.dup
        else
          @params[:n_components].times do
            comp_vec = ::Rumale::Utils.rand_uniform(n_features, sub_rng)
            @params[:max_iter].times do
              updated = orthogonalize(covariance_mat.dot(comp_vec))
              break if (updated.dot(comp_vec) - 1).abs < @params[:tol]

              comp_vec = updated
            end
            @components = @components.nil? ? comp_vec : Numo::NArray.vstack([@components, comp_vec])
          end
        end
        self
      end

      # Fit the model with training data, and then transform them with the learned model.
      #
      # @overload fit_transform(x) -> Numo::DFloat
      #   @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      #   @return [Numo::DFloat] (shape: [n_samples, n_components]) The transformed data
      def fit_transform(x, _y = nil)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        fit(x).transform(x)
      end

      # Transform the given data with the learned model.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The data to be transformed with the learned model.
      # @return [Numo::DFloat] (shape: [n_samples, n_components]) The transformed data.
      def transform(x)
        x = ::Rumale::Validation.check_convert_sample_array(x)

        (x - @mean).dot(@components.transpose)
      end

      # Inverse transform the given transformed data with the learned model.
      #
      # @param z [Numo::DFloat] (shape: [n_samples, n_components]) The data to be restored into original space with the learned model.
      # @return [Numo::DFloat] (shape: [n_samples, n_featuress]) The restored data.
      def inverse_transform(z)
        z = ::Rumale::Validation.check_convert_sample_array(z)

        c = @components.shape[1].nil? ? @components.expand_dims(0) : @components
        z.dot(c) + @mean
      end

      private

      def orthogonalize(pcvec)
        unless @components.nil?
          delta = @components.dot(pcvec) * @components.transpose
          delta = delta.sum(axis: 1) unless delta.shape[1].nil?
          pcvec -= delta
        end
        pcvec / Math.sqrt((pcvec**2).sum.abs) + 1.0e-12
      end
    end
  end
end
