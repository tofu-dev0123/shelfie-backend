module V1
  module Me
    class BaseController < V1::BaseController
      before_action :authenticate_user!
    end
  end
end
