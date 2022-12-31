# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::KernelMachine::KernelRidgeClassifier do
  let(:x) { dataset[0] }
  let(:y) { dataset[1] }
  let(:classes) { y.to_a.uniq.sort }
  let(:n_samples) { x.shape[0] }
  let(:n_classes) { classes.size }
  let(:kernel_mat) { Rumale::PairwiseMetric.rbf_kernel(x, nil, 1.0) }
  let(:estimator) { described_class.new(reg_param: 1.0).fit(kernel_mat, y) }
  let(:func_vals) { estimator.decision_function(kernel_mat) }
  let(:predicted) { estimator.predict(kernel_mat) }
  let(:score) { estimator.score(kernel_mat, y) }

  context 'when binary classification problem' do
    let(:dataset) { xor_dataset }

    it 'classifies xor data.', :aggregate_failures do
      expect(estimator.weight_vec).to be_a(Numo::DFloat)
      expect(estimator.weight_vec).to be_contiguous
      expect(estimator.weight_vec.ndim).to eq(2)
      expect(estimator.weight_vec.shape[0]).to eq(n_samples)
      expect(estimator.weight_vec.shape[1]).to eq(n_classes)
      expect(estimator.classes).to be_a(Numo::Int32)
      expect(estimator.classes).to be_contiguous
      expect(estimator.classes.ndim).to eq(1)
      expect(estimator.classes.shape[0]).to eq(2)
      expect(func_vals).to be_a(Numo::DFloat)
      expect(func_vals).to be_contiguous
      expect(func_vals.ndim).to eq(2)
      expect(func_vals.shape[0]).to eq(n_samples)
      expect(func_vals.shape[1]).to eq(n_classes)
      expect(predicted).to be_a(Numo::Int32)
      expect(predicted).to be_contiguous
      expect(predicted.ndim).to eq(1)
      expect(predicted.shape[0]).to eq(n_samples)
      expect(predicted).to eq(y)
      expect(score).to eq(1.0)
    end
  end

  context 'when multiclass classification problem' do
    let(:dataset) { three_clusters_dataset }

    it 'classifies three clusters.', :aggregate_failures do
      expect(estimator.classes).to be_a(Numo::Int32)
      expect(estimator.classes).to be_contiguous
      expect(estimator.classes.ndim).to eq(1)
      expect(estimator.classes.shape[0]).to eq(n_classes)
      expect(estimator.weight_vec).to be_a(Numo::DFloat)
      expect(estimator.weight_vec).to be_contiguous
      expect(estimator.weight_vec.ndim).to eq(2)
      expect(estimator.weight_vec.shape[0]).to eq(n_samples)
      expect(estimator.weight_vec.shape[1]).to eq(n_classes)
      expect(func_vals).to be_a(Numo::DFloat)
      expect(func_vals).to be_contiguous
      expect(func_vals.ndim).to eq(2)
      expect(func_vals.shape[0]).to eq(n_samples)
      expect(func_vals.shape[1]).to eq(n_classes)
      expect(predicted).to be_a(Numo::Int32)
      expect(predicted).to be_contiguous
      expect(predicted.ndim).to eq(1)
      expect(predicted.shape[0]).to eq(n_samples)
      expect(predicted).to eq(y)
      expect(score).to eq(1.0)
    end
  end
end
