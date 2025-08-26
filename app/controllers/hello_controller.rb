class HelloController < ApplicationController
    def index
      render inertia: 'hello', props: {
        # name: params.fetch(:name, 'World'),
        name: "World"
      }
    end
  end