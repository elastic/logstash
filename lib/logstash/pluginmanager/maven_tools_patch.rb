# This adds the "repo" element to the jar-dependencies DSL
# allowing a gemspec to require a jar that exists in a custom
# maven repository
# Example:
#   gemspec.requirements << "repo http://localhosty/repo"
require 'maven/tools/dsl/project_gemspec'
class Maven::Tools::DSL::ProjectGemspec
  def repo(url)
    @parent.repository(:id => url, :url => url)
  end
end

