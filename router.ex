defmodule HelloWeb.Router do
  use HelloWeb, :router

  # session provision
  # persist
  # each user gets
  #    email record
  #    initial provisioning of 10 sets of (1 access token, 4 refresh tokens)
  #        first set will be emailed to him, he can req any subsequently
  #        the sets and tokens within are ordered -- use of any subsequently will invalidate all before
  #    a client-idx that is scoped to the session
  # each session gets some data and a finite window of time, possibly (by id) an initial selector
  #
  # ok
  # with this, we also hydrate the lwt heartbeat svc (and update him thereafter) with a bit seq that masks each users seq of tokens, 111100000... signifies the first 4 tokens are invalidated, the fifth is active
  # (use 4 bytes' encoding to send this "succinct vec" across 50 tokens, access|refresh, in "unambiguous" order

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
#    plug :accepts, ["json"]
    #    plug CORSPlug, origin: "http://localhost:5005"
    plug CORSPlug, origin: ["*" ]    
    plug :accepts, ["json"]
#      plug Corsica, origins: [
#	"http://localhost:4000",
#	"http://localhost:5005",
#	"http://localhost:8080"
 #     ], allow_headers: ["accept", "content-type", "authorization"], allow_credentials: true, log: [rejected: :error, invalid: :warn, accepted: :debug]
  end

#  scope "/", HelloWeb do
#    pipe_through :browser

#    get "/", PageController, :index
#  end

  # Other scopes may use custom stacks.
  scope "/api/v1", HelloWeb do
    pipe_through :api
    resources "/chunks", ChunksController
    get "/chunks", ChunksController, :chunks
    post "/new_client_stream_src_connection", ChunksController, :new_client_stream_src_connection
    get "/apreta00", ChunksController, :apreta00
    post "/newmetarecord", ChunksController, :newmetarecord    
    get "/apretamo", ChunksController, :apretamo
    get "/apretacounts", ChunksController, :apretacounts
    get "/apretauserzerostate", ChunksController, :apretauserzerostate
    get "/writepairsfile", ChunksController, :writepairsfile
    post "/fulfillvideochunk", ChunksController, :fulfillvideochunk
    post "/checkoutchunks", ChunksController, :checkoutchunks
    get "/allstreams", ChunksController, :allstreams
    get "/allchunksaftertstamp", ChunksController, :allchunksaftertstamp

    post "/fulfillaudiochunk", ChunksController, :fulfillaudiochunk    
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HelloWeb.Telemetry
    end
    scope "/api/v1", ApiExample do
      pipe_through :api
      get "/users", UserController, :index
    end
  end
end
