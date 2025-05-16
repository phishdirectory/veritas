# frozen_string_literal: true

# .git-hooks/pre_commit/annotaterb.rb
module Overcommit::Hook::PreCommit
  class Annotaterb < Base
    def run
      result_routes = `annotaterb routes`
      result_models = `annotaterb models`
      if $?.exitstatus != 0
        return :fail, "annotaterb failed:\n#{result_routes}\n#{result_models}"
      end

      :pass
    end

  end
end
