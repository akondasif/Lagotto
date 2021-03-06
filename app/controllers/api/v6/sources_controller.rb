class Api::V6::SourcesController < Api::BaseController
  swagger_controller :sources, "Sources"

  swagger_api :index do
    summary 'Returns all sources, sorted by group'
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  swagger_api :show do
    summary 'Returns source by name'
    param :path, :name, :string, :required, "Source name"
    response :ok
    response :unprocessable_entity
    response :not_found
  end

  def index
    collection = Source.visible.includes(:group)
    @sources = collection.decorate
  end

  def show
    source = Source.where(name: params[:id]).first
    @source = source.decorate
  end
end
