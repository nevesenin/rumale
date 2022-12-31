# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rumale::Preprocessing::L1Normalizer do
  let(:n_samples) { 10 }
  let(:n_features) { 4 }
  let(:normalizer) { described_class.new }
  let(:normalized) { normalizer.transform(x) }

  context 'when norm vector does not contain zero' do
    let(:x) { Numo::DFloat.new(n_samples, n_features).rand - 0.5 }

    it 'normalizes each sample with l1 norm', :aggregate_failures do
      expect((normalized.abs.sum - n_samples).abs).to be < 1.0e-6
      expect(normalizer.norm_vec).to be_a(Numo::DFloat)
      expect(normalizer.norm_vec.ndim).to eq(1)
      expect(normalizer.norm_vec.shape[0]).to eq(n_samples)
    end
  end

  context 'when norm vector consists of zero values' do
    let(:x) do
      Numo::DFloat.new(n_samples, n_features).rand.tap { |x| x[0, true] = Numo::DFloat.zeros(n_features) }
    end

    it 'does not normalize vectors with zero norm', :aggregate_failures do
      expect(normalized[0, true]).to eq(x[0, true])
      expect(normalizer.norm_vec[0]).to eq(1)
    end
  end
end
