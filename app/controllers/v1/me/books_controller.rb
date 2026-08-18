module V1
  module Me
    class BooksController < BaseController
      def create
        Rails.logger.debug "V1::Me::BooksController#create: user_id=#{current_user.id}"
        UserBooks::CreateService.call(
          current_user: current_user,
          isbn: book_params[:isbn],
          content: book_params[:content]
        )
        render json: { message: I18n.t("messages.me.books.created") }, status: :created
      end

      def update
        Rails.logger.debug "V1::Me::BooksController#update: user_id=#{current_user.id}"
        UserBooks::UpdateService.call(
          current_user: current_user,
          isbn: params[:isbn],
          content: update_params[:content]
        )
        render json: { message: I18n.t("messages.me.books.updated") }, status: :ok
      end

      def destroy
        Rails.logger.debug "V1::Me::BooksController#destroy: user_id=#{current_user.id}"
        UserBooks::DestroyService.call(current_user: current_user, isbn: params[:isbn])
        render json: { message: I18n.t("messages.me.books.destroyed") }, status: :ok
      end

      private

      def book_params
        params.permit(:isbn, :content)
      end

      def update_params
        params.permit(:content)
      end
    end
  end
end
