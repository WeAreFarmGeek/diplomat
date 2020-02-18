# frozen_string_literal: true

Then 'I should be able to get and put keys' do
  # High-fructose Corn Syrup
  Diplomat.put('drink', 'Irn Bru')
  expect(Diplomat.get('drink')).to eq('Irn Bru')

  # Sugar
  Diplomat::Kv.put('cake', 'Sponge')
  expect(Diplomat::Kv.get('cake')).to eq('Sponge')
end
