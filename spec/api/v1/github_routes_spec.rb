require 'rails_helper'

module V1
  describe GithubRoutes do
    describe 'POST /api/v1/github/push' do
      let(:payload_body) do
        post_data = {
          repository: {
            full_name: 'account/repository'
          },
          ref: 'refs/header/master'
        }
        Oj.dump(post_data)
      end
      let(:headers) do
        { 'HTTP_X_HUB_SIGNATURE': signature, 'HTTP_CONTENT_TYPE' => 'application/json' }
      end

      context 'when valid signature' do
        sha1 = OpenSSL::Digest.new('sha1')
        let(:signature) { 'sha1=' + OpenSSL::HMAC.hexdigest(sha1, ENV['GITHUB_SECRET_KEY'], payload_body) }

        it 'should be return success' do
          allow(Github::DeployWorker).to receive(:perform_async)
          allow_any_instance_of(Helper::GithubHelper).to receive(:detect_auto_deploy_service).and_return(cluster: 'default', service: 'development')

          post '/api/v1/github/push', params: payload_body, headers: headers
          expect(response).to have_http_status :created
          expect(response.body).to be_json_eql('success'.to_json).at_path('result')
        end
      end

      context 'when invalid signature' do
        let(:signature) { 'sha1=invalid_signature' }

        it 'should be return error' do
          post '/api/v1/github/push', params: payload_body, headers: headers
          expect(response).to have_http_status :forbidden
          expect(response.body).to be_json_eql('Signature do not match.'.to_json).at_path('error')
        end
      end
    end
  end
end
