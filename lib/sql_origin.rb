# Container module for all SQL:Origin methods.

module SQLOrigin
  # Paths or path prefixes that are filtered from the backtrace.
  LIBRARY_PATHS = %w(
    vendor
  )

  def self.log_lines=(num)
    @log_lines = num
  end

  def self.log_lines
    @log_lines || 3
  end

  # @return [Array<String>] The backtrace less library paths.

  def self.filter?
    @filter || true
  end

  def self.filter=(filter)
    @filter = filter
  end

  def self.backtrace
    if filter?
      filtered_backtrace
    else
      unfiltered_backtrace
    end
  end

  def self.unfiltered_backtrace
    caller.map do |line|
      line.sub(/^#{Regexp.escape Rails.root.to_s}\//, '')
    end
  end

  def self.filtered_backtrace
    unfiltered_backtrace.select do |line|
      !line.starts_with?("/") &&
        !line.starts_with?("(") &&
        LIBRARY_PATHS.none? { |path| line.starts_with?(path) }
    end
  end

  # Enables SQL:Origin backtrace logging to the Rails log.

  def self.append_to_log
    %w( PostgreSQLAdapter MysqlAdapter Mysql2Adapter OracleAdapter SQLiteAdapter ).each do |name|
      adapter = ActiveRecord::ConnectionAdapters.const_get(name.to_sym) rescue nil
      if adapter
        adapter.send :include, SQLOrigin::LogHook
      end
    end
    ActiveRecord::LogSubscriber.send :include, SQLOrigin::LogSubscriber
  end

  # Enables SQL:Origin backtrace logging to SQL query comments.

  def self.append_to_query
    %w( PostgreSQLAdapter MysqlAdapter Mysql2Adapter OracleAdapter SQLiteAdapter ).each do |name|
      adapter = ActiveRecord::ConnectionAdapters.const_get(name.to_sym) rescue nil
      if adapter
        adapter.send :include, SQLOrigin::QueryAppendHook
      end
    end
  end
end

require 'sql_origin/hooks'
