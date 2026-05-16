require_relative '../lib/cache'


RSpec.describe Cache do
  let(:cache) { Cache.new(':memory:', 'test') }

  it 'stores and returns value on cache miss' do
    value = cache.fetch('https://example.com') { 'gibberish' }

    expect(value).to eq('gibberish')
  end

  it 'returns cached value without running block on cache hit' do
    cache.fetch('https://example.com') { 'gibberish' }
    value = cache.fetch('https://example.com') { fail }

    expect(value).to eq('gibberish')
  end

  it 'refetches after marking key as stale' do
    cache.fetch('https://example.com') { 'old' }
    cache.mark_as_stale('https://example.com')
    cache.fetch('https://example.com') { 'new' }
    value = cache.fetch('https://example.com') { fail }

    expect(value).to eq('new')
  end

  it 'keeps cached values isolated by partition name' do
    alpha = Cache.new(':memory:', 'alpha')
    beta = Cache.new(':memory:', 'beta')
    beta.instance_variable_set(:@db, alpha.instance_variable_get(:@db))

    alpha.fetch('https://example.com') { 'first' }
    value = beta.fetch('https://example.com') { 'second' }

    expect(value).to eq('second')
  end

  it 'lists partition names' do
    alpha = Cache.new(':memory:', 'alpha')
    beta = Cache.new(':memory:', 'beta')
    gamma = Cache.new(':memory:', 'gamma')
    beta.instance_variable_set(:@db, alpha.instance_variable_get(:@db))
    gamma.instance_variable_set(:@db, alpha.instance_variable_get(:@db))
    alpha.fetch('https://example.com/1') { 'first' }
    beta.fetch('https://example.com/2') { 'second' }

    expect(gamma.list_partitions).to eq(%w(alpha beta))
  end

  it 'resolves :yesterday to the most recent non-today yyyy-mm-dd partition' do
    cache = Cache.new(':memory:', '2026-05-14')
    previous = Cache.new(':memory:', '2026-05-15')
    today = Cache.new(':memory:', '2026-05-16')
    draft = Cache.new(':memory:', 'draft')
    yesterday = Cache.new(':memory:', 'placeholder')
    [previous, today, draft, yesterday].each do |each|
      each.instance_variable_set(:@db, cache.instance_variable_get(:@db))
    end
    cache.fetch('https://example.com/1') { 'first' }
    previous.fetch('https://example.com/2') { 'second' }
    today.fetch('https://example.com/3') { 'third' }
    draft.fetch('https://example.com/4') { 'fourth' }

    allow(Date).to receive(:today).and_return(Date.iso8601('2026-05-16'))
    yesterday.instance_variable_set(:@partition, yesterday.send(:handle_today_and_yesterday, :yesterday))

    expect(yesterday.partition).to eq('2026-05-15')
  end

  it 'drops partition entries' do
    alpha = Cache.new(':memory:', 'alpha')
    beta = Cache.new(':memory:', 'beta')
    beta.instance_variable_set(:@db, alpha.instance_variable_get(:@db))

    alpha.fetch('https://example.com') { 'first' }
    beta.fetch('https://example.com') { 'second' }

    expect(alpha.drop_partition!('alpha')).to eq(1)
    expect(beta.fetch('https://example.com') { fail }).to eq('second')
  end

  it 'counts cached responses' do
    cache.fetch('https://example.com/1') { 'first' }
    cache.fetch('https://example.com/2') { 'second' }

    expect(cache.count_cached_responses).to eq(2)
  end
end
