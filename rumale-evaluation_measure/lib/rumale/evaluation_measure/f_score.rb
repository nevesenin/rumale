# frozen_string_literal: true

require 'rumale/base/evaluator'
require 'rumale/evaluation_measure/precision_recall'

module Rumale
  # This module consists of the classes for model evaluation.
  module EvaluationMeasure
    # FScore is a class that calculates the F1-score of the predicted labels.
    #
    # @example
    #   require 'rumale/evaluation_measure/f_score'
    #
    #   evaluator = Rumale::EvaluationMeasure::FScore.new
    #   puts evaluator.score(ground_truth, predicted)
    class FScore
      include ::Rumale::Base::Evaluator
      include ::Rumale::EvaluationMeasure::PrecisionRecall

      # Return the average type for calculation of F1-score.
      # @return [String] ('binary', 'micro', 'macro')
      attr_reader :average

      # Create a new evaluation measure calculater for F1-score.
      #
      # @param average [String] The average type ('binary', 'micro', 'macro')
      def initialize(average: 'binary')
        @average = average
      end

      # Calculate average F1-score
      #
      # @param y_true [Numo::Int32] (shape: [n_samples]) Ground truth labels.
      # @param y_pred [Numo::Int32] (shape: [n_samples]) Predicted labels.
      # @return [Float] Average F1-score
      def score(y_true, y_pred)
        case @average
        when 'binary'
          f_score_each_class(y_true, y_pred).last
        when 'micro'
          micro_average_f_score(y_true, y_pred)
        when 'macro'
          macro_average_f_score(y_true, y_pred)
        end
      end
    end
  end
end
