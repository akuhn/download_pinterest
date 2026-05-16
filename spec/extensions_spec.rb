require_relative '../lib/extensions'


RSpec.describe 'extensions' do
  describe Hash do
    it 'fetches string-keyed values via method_missing' do
      hash = { 'foo' => 42 }

      expect(hash.foo).to eq(42)
    end
  end

  describe String do
    it 'builds a proc that digs by dotted path' do
      rows = [
        { 'foo' => { 'bar' => 1 } },
        { 'foo' => { 'bar' => 2 } }
      ]

      expect(rows.map(&'foo.bar')).to eq([1, 2])
    end
  end
end
