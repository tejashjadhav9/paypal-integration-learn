class OrdersController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :paypal_init, :except => [:index]
    def index; end
    def create_order
        
        price = '100.00'
        request = PayPalCheckoutSdk::Orders::OrdersCreateRequest::new
        request.request_body({
          :intent => 'CAPTURE',
          :purchase_units => [
            {
              :amount => {
                :currency_code => 'USD',
                :value => price
              }
            }
          ]
        })
        begin
          response = @client.execute request
          order = Order.new
          order.price = price.to_i
          order.token = response.result.id
          if order.save
            return render :json => {:token => response.result.id}, :status => :ok
          end
        rescue PayPalHttp::HttpError => ioe
          # HANDLE THE ERROR
        end
    end


    def capture_order
        request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new params[:order_id]
        begin
          response = @client.execute request
          order = Order.find_by :token => params[:order_id]
          order.paid = response.result.status == 'COMPLETED'
          if order.save
            return render :json => {:status => response.result.status}, :status => :ok
          end
        rescue PayPalHttp::HttpError => ioe
          # HANDLE THE ERROR
        end
    end

    private
    def paypal_init
      client_id = 'AWiOeW3P4mKVTMZ6WX_JJigs5dHdQ_xC46pbw6xdmYBQv2VPTLLvrogyo5zwUYJ6qviOyNdWigoFl3dH'
      client_secret = 'EF7T5BQqNzUl4ahT0HsnJ7IANJbDepEn0p-WYHgsHQ7vDa2U39d7OOiUl3Ja_kjsn94vT3HPC_T7WIL6'
      environment = PayPal::SandboxEnvironment.new client_id, client_secret
      @client = PayPal::PayPalHttpClient.new environment
    end
  end
