# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Clustering::SingleLinkage do
  let(:dataset) { Rumale::Dataset.make_moons(200, noise: 0.03, random_seed: 1) }
  let(:samples) { dataset[0] }
  let(:y) { dataset[1] }
  let(:n_samples) { samples.shape[0] }
  let(:metric) { 'euclidean' }
  let(:analyzer) { described_class.new(n_clusters: 2, metric: metric) }
  let(:cluster_labels) { analyzer.fit_predict(x) }

  shared_examples 'cluster analysis' do
    it 'finds clusters', :aggregate_failures do
      expect(cluster_labels).to be_a(Numo::Int32)
      expect(cluster_labels).to be_contiguous
      expect(cluster_labels.ndim).to eq(1)
      expect(cluster_labels.shape[0]).to eq(n_samples)
      expect(cluster_labels.eq(0).count).to eq(100)
      expect(cluster_labels.eq(1).count).to eq(100)
      expect(analyzer.labels).to be_a(Numo::Int32)
      expect(analyzer.labels).to be_contiguous
      expect(analyzer.labels.ndim).to eq(1)
      expect(analyzer.labels.shape[0]).to eq(n_samples)
      expect(analyzer.score(x, y)).to eq(1)
    end
  end

  context "when metric is 'euclidean'" do
    let(:x) { samples }
    let(:metric) { 'euclidean' }

    it_behaves_like 'cluster analysis'
  end

  context "when metric is 'precomputed'" do
    let(:x) { Rumale::PairwiseMetric.manhattan_distance(samples) }
    let(:metric) { 'precomputed' }

    it_behaves_like 'cluster analysis'

    it 'raises ArgumentError when given a non-square matrix', :aggregate_failures do
      expect { analyzer.fit(Numo::DFloat.new(3, 2).rand) }.to raise_error(ArgumentError)
      expect { analyzer.fit_predict(Numo::DFloat.new(2, 3).rand) }.to raise_error(ArgumentError)
    end
  end
end
