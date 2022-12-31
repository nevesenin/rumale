# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::KernelApproximation::RBF do
  let(:x) { three_clusters_dataset[0] }
  let(:n_samples) { x.shape[0] }
  let(:n_features) { x.shape[1] }
  let(:n_components) { 1024 }
  let(:transformer) { described_class.new(gamma: 1.0, n_components: n_components, random_seed: 1) }
  let(:mapped_x) { transformer.fit_transform(x) }
  let(:inner_mat) { mapped_x.dot(mapped_x.transpose) }
  let(:kernel_mat) do
    res = Numo::DFloat.zeros(n_samples, n_samples)
    n_samples.times do |m|
      n_samples.times do |n|
        distance = Math.sqrt(((x[m, true] - x[n, true])**2).sum)
        res[m, n] = Math.exp(-distance**2)
      end
    end
    res
  end
  let(:mse) { ((kernel_mat - inner_mat)**2).sum.fdiv(n_samples**2) }

  it 'has a small approximation error for the RBF kernel function', :aggregate_failures do
    expect(mse).to be < 0.01
    expect(mapped_x).to be_a(Numo::DFloat)
    expect(mapped_x).to be_contiguous
    expect(mapped_x.ndim).to eq(2)
    expect(mapped_x.shape[0]).to eq(n_samples)
    expect(mapped_x.shape[1]).to eq(n_components)
    expect(transformer.random_mat).to be_a(Numo::DFloat)
    expect(transformer.random_mat).to be_contiguous
    expect(transformer.random_mat.ndim).to eq(2)
    expect(transformer.random_mat.shape[0]).to eq(n_features)
    expect(transformer.random_mat.shape[1]).to eq(n_components)
    expect(transformer.random_vec).to be_a(Numo::DFloat)
    expect(transformer.random_vec).to be_contiguous
    expect(transformer.random_vec.ndim).to eq(1)
    expect(transformer.random_vec.shape[0]).to eq(n_components)
  end
end
