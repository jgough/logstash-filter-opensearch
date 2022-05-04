module OpenSearchHelper
  def self.get_host_port
    if ENV["INTEGRATION"] == "true"
      "opensearch:9200"
    else
      "localhost:9200"
    end
  end

  def self.get_client
    OpenSearch::Client.new(:hosts => [get_host_port])
  end

  def self.doc_type
    if OpenSearchHelper.opensearch_version_satisfies?(">=8")
      nil
    elsif OpenSearchHelper.opensearch_version_satisfies?(">=7")
      "_doc"
    else
      "doc"
    end
  end

  def self.index_doc(opensearch, params)
    type = doc_type
    params[:type] = doc_type unless type.nil?
    opensearch.index(params)
  end

  def self.opensearch_version
    ENV['OPENSEARCH_VERSION']
  end

  def self.opensearch_version_satisfies?(*requirement)
    opensearch_version = RSpec.configuration.filter[:opensearch_version] || ENV['OPENSEARCH_VERSION']
    if opensearch_version.nil?
      puts "Info: OPENSEARCH_VERSION or 'opensearch_version' tag wasn't set. Returning false to all `opensearch_version_satisfies?` call."
      return false
    end
    opensearch_release_version = Gem::Version.new(opensearch_version).release
    Gem::Requirement.new(requirement).satisfied_by?(opensearch_release_version)
  end
end
