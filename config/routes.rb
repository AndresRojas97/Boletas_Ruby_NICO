Rails.application.routes.draw do
  resources :boletas, path: "boletas", only: [ :index, :new, :create, :update, :destroy ] do
    collection do
      delete :limpiar_incompletas
    end
  end
  root to: redirect("/boletas/new")
end
