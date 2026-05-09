require %(sqlite3)


class Cache
  def initialize(path, partition)
    @partition = partition
    @db = SQLite3::Database.new(path)

    @db.execute %{
      CREATE TABLE IF NOT EXISTS cache (
        partition TEXT,
        key TEXT,
        content BLOB,
        timestamp DATETIME DEFAULT current_timestamp
      )
    }

    @db.execute %{
      CREATE INDEX IF NOT EXISTS cache_partition_key
      ON cache(partition, key)
    }
  end

  def fetch(key)
    raise unless block_given?

    row = @db.get_first_row(
      'SELECT content FROM cache WHERE partition = ? AND key = ? ORDER BY timestamp DESC LIMIT 1',
      [@partition, key]
    )

    content = row && row.first
    content = nil if content == %(__marked_as_stale_cache_entry__)
    return content if content
    content = yield

    @db.execute(
      'INSERT INTO cache (partition, key, content) VALUES (?, ?, ?)',
      [@partition, key, content]
    )

    content
  end

  def most_recent_content(key)
    row = @db.get_first_row(
      'SELECT content FROM cache WHERE key = ? AND content != ? ORDER BY timestamp DESC LIMIT 1',
      [key, %(__marked_as_stale_cache_entry__)]
    )

    row && row.first
  end

  def mark_as_stale(key)
    @db.execute(
      'INSERT INTO cache (partition, key, content) VALUES (?, ?, ?)',
      [@partition, key, %(__marked_as_stale_cache_entry__)]
    )
  end

  def delete(key)
    @db.execute(
      'DELETE FROM cache WHERE partition = ? AND key = ?',
      [@partition, key]
    )
  end

  def list_partitions
    rows = @db.execute %{
      SELECT DISTINCT partition
      FROM cache
      WHERE partition IS NOT NULL
      ORDER BY partition
    }

    rows.flatten
  end

  def drop_partition!(partition)
    @db.execute(
      'DELETE FROM cache WHERE partition = ?',
      [partition]
    )
    @db.changes
  end
end
