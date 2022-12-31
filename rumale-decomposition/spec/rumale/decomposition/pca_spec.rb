# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Decomposition::PCA do
  let(:x) { two_clusters_dataset[0] }
  let(:n_components) { 16 }
  let(:solver) { 'fpt' }
  let(:decomposer) { described_class.new(n_components: n_components, solver: solver, tol: 1.0e-8, random_seed: 1) }
  let(:samples) { Rumale::KernelApproximation::RBF.new(gamma: 1.0, n_components: 32, random_seed: 1).fit_transform(x) }
  let(:sub_samples) { decomposer.fit_transform(samples) }
  let(:rec_samples) { decomposer.inverse_transform(sub_samples) }
  let(:mse) { Numo::NMath.sqrt(((samples - rec_samples)**2).sum(axis: 1)).mean }
  let(:n_samples) { samples.shape[0] }
  let(:n_features) { samples.shape[1] }

  shared_examples 'projection into subspace' do
    it 'projects high-dimensinal data into subspace', :aggregate_failures do
      expect(sub_samples).to be_a(Numo::DFloat)
      expect(sub_samples).to be_contiguous
      expect(sub_samples.ndim).to eq(2)
      expect(sub_samples.shape[0]).to eq(n_samples)
      expect(sub_samples.shape[1]).to eq(n_components)
      expect(rec_samples).to be_a(Numo::DFloat)
      expect(rec_samples).to be_contiguous
      expect(rec_samples.ndim).to eq(2)
      expect(rec_samples.shape[0]).to eq(n_samples)
      expect(rec_samples.shape[1]).to eq(n_features)
      expect(decomposer.components).to be_a(Numo::DFloat)
      expect(decomposer.components).to be_contiguous
      expect(decomposer.components.ndim).to eq(2)
      expect(decomposer.components.shape[0]).to eq(n_components)
      expect(decomposer.components.shape[1]).to eq(n_features)
      expect(decomposer.mean).to be_a(Numo::DFloat)
      expect(decomposer.mean).to be_contiguous
      expect(decomposer.mean.ndim).to eq(1)
      expect(decomposer.mean.shape[0]).to eq(n_features)
      expect(mse).to be <= 0.1
    end
  end

  shared_examples 'projection into one-dimensional subspace' do
    let(:n_components) { 1 }
    let(:samples) { x }
    let(:sub_samples) { decomposer.fit_transform(samples).expand_dims(1).dup }

    it 'projects data into one-dimensional subspace', :aggregate_failures do
      expect(sub_samples).to be_a(Numo::DFloat)
      expect(sub_samples).to be_contiguous
      expect(sub_samples.ndim).to eq(2)
      expect(sub_samples.shape[0]).to eq(n_samples)
      expect(sub_samples.shape[1]).to eq(n_components)
      expect(rec_samples).to be_a(Numo::DFloat)
      expect(rec_samples).to be_contiguous
      expect(rec_samples.ndim).to eq(2)
      expect(rec_samples.shape[0]).to eq(n_samples)
      expect(rec_samples.shape[1]).to eq(n_features)
      expect(decomposer.components).to be_a(Numo::DFloat)
      expect(decomposer.components).to be_contiguous
      expect(decomposer.components.ndim).to eq(1)
      expect(decomposer.components.shape[0]).to eq(n_features)
      expect(decomposer.mean).to be_a(Numo::DFloat)
      expect(decomposer.mean).to be_contiguous
      expect(decomposer.mean.ndim).to eq(1)
      expect(decomposer.mean.shape[0]).to eq(n_features)
      expect(mse).to be <= 0.5
    end
  end

  context 'when solver is fix point algorithm' do
    it_behaves_like 'projection into subspace'
    it_behaves_like 'projection into one-dimensional subspace'
  end

  context 'when solver is eigen value decomposition' do
    let(:solver) { 'evd' }

    it_behaves_like 'projection into subspace'
    it_behaves_like 'projection into one-dimensional subspace'
  end

  context 'when solver is automatic' do
    let(:solver) { 'auto' }

    context 'with Numo::Linalg is loaded' do
      it 'chooses "evd" solver' do
        expect(decomposer.params[:solver]).to eq('evd')
      end
    end

    context 'with Numo::Linalg is not loaded' do
      before { hide_const('Numo::Linalg') }

      it 'chooses "fpt" solver' do
        expect(decomposer.params[:solver]).to eq('fpt')
      end
    end
  end
end
