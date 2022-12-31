# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Manifold::TSNE do
  # let(:samples) do
  #  Rumale::KernelApproximation::RBF.new(n_components: 32, random_seed: 1).fit_transform(two_clusters_dataset[0])
  # end
  let(:base_samples) { two_clusters_dataset[0] }
  let(:samples) { base_samples.dot(Rumale::Utils.rand_normal([base_samples.shape[1], 128], Random.new(1), 0.0, 0.001)) }
  let(:n_samples) { samples.shape[0] }
  let(:n_features) { samples.shape[1] }
  let(:n_components) { 2 }
  let(:metric) { 'euclidean' }
  let(:perplexity) { 30 }
  let(:tol) { nil }
  let(:verbose) { false }
  let(:max_iter) { 50 }
  let(:tsne) do
    described_class.new(n_components: n_components, metric: metric, max_iter: max_iter, tol: tol, init: 'pca',
                        perplexity: perplexity, verbose: verbose, random_seed: 1)
  end
  let(:init_kl) do
    described_class.new(n_components: n_components, metric: metric, max_iter: 0, tol: tol, init: 'pca',
                        perplexity: perplexity, verbose: verbose, random_seed: 1).fit(x).kl_divergence
  end
  let(:low_samples) { tsne.fit_transform(x) }

  context 'when metric is "euclidean"' do
    let(:metric) { 'euclidean' }
    let(:x) { samples }

    it 'maps high-dimensional data into low-dimensional data', :aggregate_failures do
      expect(low_samples).to be_a(Numo::DFloat)
      expect(low_samples).to be_contiguous
      expect(low_samples.ndim).to eq(2)
      expect(low_samples.shape[0]).to eq(n_samples)
      expect(low_samples.shape[1]).to eq(n_components)
      expect(tsne.embedding).to be_a(Numo::DFloat)
      expect(tsne.embedding).to be_contiguous
      expect(tsne.embedding.ndim).to eq(2)
      expect(tsne.embedding.shape[0]).to eq(n_samples)
      expect(tsne.embedding.shape[1]).to eq(n_components)
      expect(tsne.n_iter).to eq(max_iter)
      expect(tsne.kl_divergence).to be_a(Float)
      expect(tsne.kl_divergence).not_to be_nil
      expect(tsne.kl_divergence).to be < init_kl
    end

    context 'when tol parameter is given' do
      let(:tol) { 1 }

      it 'terminates optimization based on the tol parameter', :aggregate_failures do
        expect(low_samples).to be_a(Numo::DFloat)
        expect(low_samples).to be_contiguous
        expect(low_samples.ndim).to eq(2)
        expect(low_samples.shape[0]).to eq(n_samples)
        expect(low_samples.shape[1]).to eq(n_components)
        expect(tsne.embedding).to be_a(Numo::DFloat)
        expect(tsne.embedding).to be_contiguous
        expect(tsne.embedding.ndim).to eq(2)
        expect(tsne.embedding.shape[0]).to eq(n_samples)
        expect(tsne.embedding.shape[1]).to eq(n_components)
        expect(tsne.n_iter).to be < max_iter
        expect(tsne.kl_divergence).to be_a(Float)
        expect(tsne.kl_divergence).not_to be_nil
        expect(tsne.kl_divergence).to be < init_kl
      end
    end

    context 'when verbose is "true"' do
      let(:verbose) { true }
      let(:perplexity) { 200 }
      let(:max_iter) { 100 }

      it 'outputs debug messages', :aggregate_failures do
        expect { tsne.fit(x) }.to output(/t-SNE/).to_stdout
      end
    end
  end

  context 'when metric is "precomputed"' do
    let(:metric) { 'precomputed' }
    let(:x) { Rumale::PairwiseMetric.euclidean_distance(samples) }

    it 'maps high-dimensional data represented by distance matrix', :aggregate_failures do
      expect(low_samples).to be_a(Numo::DFloat)
      expect(low_samples).to be_contiguous
      expect(low_samples.ndim).to eq(2)
      expect(low_samples.shape[0]).to eq(n_samples)
      expect(low_samples.shape[1]).to eq(n_components)
      expect(tsne.embedding).to be_a(Numo::DFloat)
      expect(tsne.embedding).to be_contiguous
      expect(tsne.embedding.ndim).to eq(2)
      expect(tsne.embedding.shape[0]).to eq(n_samples)
      expect(tsne.embedding.shape[1]).to eq(n_components)
      expect(tsne.n_iter).to eq(max_iter)
      expect(tsne.kl_divergence).to be_a(Float)
      expect(tsne.kl_divergence).not_to be_nil
      expect(tsne.kl_divergence).to be < init_kl
    end

    it 'raises ArgumentError when given a non-square matrix', :aggregate_failures do
      expect { tsne.fit(Numo::DFloat.new(5, 3).rand) }.to raise_error(ArgumentError)
    end
  end
end
