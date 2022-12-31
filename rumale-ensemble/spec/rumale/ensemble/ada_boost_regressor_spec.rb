# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Ensemble::AdaBoostRegressor do
  let(:x) { two_clusters_dataset[0] }
  let(:n_samples) { x.shape[0] }
  let(:n_features) { x.shape[1] }
  let(:estimator) do
    described_class.new(n_estimators: 10, threshold: 0.02, criterion: 'mae', max_features: 2, random_seed: 9).fit(x, y)
  end
  let(:predicted) { estimator.predict(x) }
  let(:score) { estimator.score(x, y) }

  context 'when single target problem' do
    let(:y) { x[true, 0] + x[true, 1]**2 }

    it 'learns the model for single regression problem', :aggregate_failures do
      expect(estimator.estimators).to be_a(Array)
      expect(estimator.estimators[0]).to be_a(Rumale::Tree::DecisionTreeRegressor)
      expect(estimator.feature_importances).to be_a(Numo::DFloat)
      expect(estimator.feature_importances).to be_contiguous
      expect(estimator.feature_importances.ndim).to eq(1)
      expect(estimator.feature_importances.shape[0]).to eq(n_features)
      expect(estimator.estimator_weights).to be_a(Numo::DFloat)
      expect(estimator.estimator_weights).to be_contiguous
      expect(estimator.estimator_weights.ndim).to eq(1)
      expect(estimator.estimator_weights.shape[0]).to eq(estimator.estimators.size)
      expect(predicted).to be_a(Numo::DFloat)
      expect(predicted).to be_contiguous
      expect(predicted.ndim).to eq(1)
      expect(predicted.shape[0]).to eq(n_samples)
      expect(score).to be_within(0.01).of(1.0)
    end
  end

  context 'when multi-target problem' do
    let(:y) { Numo::DFloat[x[true, 0].to_a, (x[true, 1]**2).to_a].transpose.dot(Numo::DFloat[[0.6, 0.4], [0.0, 0.1]]) }

    it 'raises ArgumentError when given multiple target values' do
      expect { estimator.fit(x, y) }.to raise_error(ArgumentError)
    end
  end
end
