describe Top4Controller, type: :controller do
  describe 'GET show' do
    it 'returns http success' do
      get :show
      expect(response).to be_success
    end
  end
end
