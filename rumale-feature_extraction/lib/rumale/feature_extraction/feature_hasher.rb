# frozen_string_literal: true

require 'mmh3'

require 'rumale/base/estimator'
require 'rumale/base/transformer'

module Rumale
  module FeatureExtraction
    # Encode array of feature-value hash to vectors with feature hashing (hashing trick).
    # This encoder turns array of mappings (Array<Hash>) with pairs of feature names and values into Numo::NArray.
    # This encoder employs signed 32-bit Murmurhash3 as the hash function.
    #
    # @example
    #   require 'rumale/feature_extraction/feature_hasher'
    #
    #   encoder = Rumale::FeatureExtraction::FeatureHasher.new(n_features: 10)
    #   x = encoder.transform([
    #     { dog: 1, cat: 2, elephant: 4 },
    #     { dog: 2, run: 5 }
    #   ])
    #
    #   # > pp x
    #   # Numo::DFloat#shape=[2,10]
    #   # [[0, 0, -4, -1, 0, 0, 0, 0, 0, 2],
    #   #  [0, 0, 0, -2, -5, 0, 0, 0, 0, 0]]
    class FeatureHasher < ::Rumale::Base::Estimator
      include ::Rumale::Base::Transformer

      # Create a new encoder for converting array of hash consisting of feature names and values to vectors
      # with feature hashing algorith.
      #
      # @param n_features [Integer] The number of features of encoded samples.
      # @param alternate_sign [Boolean] The flag indicating whether to reflect the sign of the hash value to the feature value.
      def initialize(n_features: 1024, alternate_sign: true)
        super()
        @params = {
          n_features: n_features,
          alternate_sign: alternate_sign
        }
      end

      # This method does not do anything. The encoder does not require training.
      #
      # @overload fit(x) -> FeatureHasher
      #   @param x [Array<Hash>] (shape: [n_samples]) The array of hash consisting of feature names and values.
      #   @return [FeatureHasher]
      def fit(_x = nil, _y = nil)
        self
      end

      # Encode given the array of feature-value hash.
      # This method has the same output as the transform method
      # because the encoder does not require training.
      #
      # @overload fit_transform(x) -> Numo::DFloat
      #   @param x [Array<Hash>] (shape: [n_samples]) The array of hash consisting of feature names and values.
      #   @return [Numo::DFloat] (shape: [n_samples, n_features]) The encoded sample array.
      def fit_transform(x, _y = nil)
        fit(x).transform(x)
      end

      # Encode given the array of feature-value hash.
      #
      # @param x [Array<Hash>] (shape: [n_samples]) The array of hash consisting of feature names and values.
      # @return [Numo::DFloat] (shape: [n_samples, n_features]) The encoded sample array.
      def transform(x)
        x = [x] unless x.is_a?(Array)
        n_samples = x.size

        z = Numo::DFloat.zeros(n_samples, n_features)

        x.each_with_index do |f, i|
          f.each do |k, v|
            k = "#{k}=#{v}" if v.is_a?(String)
            val = v.is_a?(String) ? 1 : v
            next if val.zero?

            h = Mmh3.hash32(k)
            fid = h.abs % n_features
            val *= h >= 0 ? 1 : -1 if alternate_sign?
            z[i, fid] = val
          end
        end

        z
      end

      private

      def n_features
        @params[:n_features]
      end

      def alternate_sign?
        @params[:alternate_sign]
      end
    end
  end
end
