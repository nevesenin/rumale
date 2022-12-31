# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::MetricLearning::FisherDiscriminantAnalysis do
  let(:dataset) { three_clusters_dataset }
  let(:x) do
    # This data occur sample overlap between classes by dimensionality reduction with PCA.
    Numo::DFloat.hstack([dataset[0], 10 * Rumale::Utils.rand_normal([dataset[0].shape[0], 1], Random.new(1))])
  end
  let(:y) { dataset[1] }
  let(:classes) { y.to_a.uniq.sort }
  let(:n_samples) { x.shape[0] }
  let(:n_features) { x.shape[1] }
  let(:n_classes) { classes.size }
  let(:n_components) { nil }

  let(:transformer) { described_class.new(n_components: n_components) }
  let(:z) { transformer.fit_transform(x, y) }

  let(:dataset_ids) { Array(0...n_samples) }
  let(:train_ids) { dataset_ids.sample(n_samples * 0.9, random: Random.new(1984)) }
  let(:test_ids) { dataset_ids - train_ids }
  let(:x_train) { x[train_ids, true].dup }
  let(:x_test) { x[test_ids, true].dup }
  let(:y_train) { y[train_ids].dup }
  let(:y_test) { y[test_ids].dup }
  let(:classifier) { Rumale::NearestNeighbors::KNeighborsClassifier.new(n_neighbors: 1) }

  context 'when n_components is not given' do
    it 'projects data into subspace', :aggregate_failures do
      expect(z).to be_a(Numo::DFloat)
      expect(z).to be_contiguous
      expect(z.ndim).to eq(2)
      expect(z.shape[0]).to eq(n_samples)
      expect(z.shape[1]).to eq(n_classes - 1)
      expect(transformer.components).to be_a(Numo::DFloat)
      expect(transformer.components).to be_contiguous
      expect(transformer.components.ndim).to eq(2)
      expect(transformer.components.shape[0]).to eq(n_classes - 1)
      expect(transformer.components.shape[1]).to eq(n_features)
      expect(transformer.mean).to be_a(Numo::DFloat)
      expect(transformer.mean).to be_contiguous
      expect(transformer.mean.ndim).to eq(1)
      expect(transformer.mean.shape[0]).to eq(n_features)
      expect(transformer.class_means).to be_a(Numo::DFloat)
      expect(transformer.class_means).to be_contiguous
      expect(transformer.class_means.ndim).to eq(2)
      expect(transformer.class_means.shape[0]).to eq(n_classes)
      expect(transformer.class_means.shape[1]).to eq(n_features)
      expect(transformer.classes).to be_a(Numo::Int32)
      expect(transformer.classes).to be_contiguous
      expect(transformer.classes.ndim).to eq(1)
      expect(transformer.classes.shape[0]).to eq(n_classes)
    end

    it 'projects data into a higly discriminating subspace', :aggregate_failures do
      z_train = transformer.fit_transform(x_train, y_train)
      z_test = transformer.transform(x_test)
      classifier.fit(z_train, y_train)
      expect(classifier.score(z_test, y_test)).to be_within(0.05).of(1.0)
    end
  end

  context 'when subspace dimensionality is one' do
    let(:n_components) { 1 }

    it 'projects data into one-dimensional subspace.', :aggregate_failures do
      expect(z).to be_a(Numo::DFloat)
      expect(z).to be_contiguous
      expect(z.ndim).to eq(1)
      expect(z.shape[0]).to eq(n_samples)
      expect(transformer.components).to be_a(Numo::DFloat)
      expect(transformer.components).to be_contiguous
      expect(transformer.components.ndim).to eq(1)
      expect(transformer.components.shape[0]).to eq(n_features)
      expect(transformer.mean).to be_a(Numo::DFloat)
      expect(transformer.mean).to be_contiguous
      expect(transformer.mean.ndim).to eq(1)
      expect(transformer.mean.shape[0]).to eq(n_features)
      expect(transformer.class_means).to be_a(Numo::DFloat)
      expect(transformer.class_means).to be_contiguous
      expect(transformer.class_means.ndim).to eq(2)
      expect(transformer.class_means.shape[0]).to eq(n_classes)
      expect(transformer.class_means.shape[1]).to eq(n_features)
    end
  end

  context 'when Numo::Linalg is not loaded' do
    before { hide_const('Numo::Linalg') }

    it 'raises Runtime error' do
      expect { transformer.fit(x, y) }.to raise_error(RuntimeError, /FisherDiscriminatAnalysis#fit requires Numo::Linalg/)
    end
  end
end
