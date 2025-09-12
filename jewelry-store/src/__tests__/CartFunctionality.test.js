import { render, screen } from '@testing-library/react';
import App from '../App';
import userEvent from '@testing-library/user-event';

// Mock product and cart data
const mockProducts = [
  {
    id: 1,
    name: 'Diamond Necklace',
    description: 'Elegant diamond necklace',
    price: 2999.99,
    image: 'https://example.com/necklace.jpg'
  },
  {
    id: 2,
    name: 'Gold Bracelet',
    description: 'Luxurious gold bracelet',
    price: 1299.99,
    image: 'https://example.com/bracelet.jpg'
  }
];

const mockCart = [
  {
    id: 1,
    product_id: 1,
    quantity: 1
  }
];

// Mock fetch API with different responses based on endpoint
global.fetch = jest.fn((url) => {
  if (url.includes('/products')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve(mockProducts)
    });
  } else if (url.includes('/cart') && !url.includes('/add') && !url.includes('/item/')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve(mockCart)
    });
  } else if (url.includes('/add')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ success: true })
    });
  } else if (url.includes('/item/') && url.includes('DELETE')) {
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ success: true })
    });
  }
  return Promise.resolve({
    ok: true,
    json: () => Promise.resolve([])
  });
});

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(() => 'test_session_id'),
  setItem: jest.fn(),
  removeItem: jest.fn()
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

describe('Cart Functionality', () => {
  beforeEach(() => {
    // Reset mocks
    fetch.mockClear();
    localStorageMock.getItem.mockClear();
    localStorageMock.setItem.mockClear();
  });
  
  test('renders cart with items', async () => {
    render(<App />);
    
    // Navigate to cart
    const cartButton = await screen.findByRole('button', { name: /cart/i });
    const user = userEvent.setup();
    await user.click(cartButton);
    
    // Check if we're on cart page
    const cartHeading = await screen.findByText('Shopping Cart');
    expect(cartHeading).toBeInTheDocument();
    
    // Check if cart item is rendered
    const diamondNecklace = await screen.findByText('Diamond Necklace');
    expect(diamondNecklace).toBeInTheDocument();
    
    // Check if price is calculated correctly
    expect(screen.getByText('$2999.99')).toBeInTheDocument();
    
    // Check if total is displayed
    expect(screen.getByText('Total: $2999.99')).toBeInTheDocument();
    
    // Check if checkout button is present
    expect(screen.getByText('Proceed to Checkout')).toBeInTheDocument();
  });
  
  test('allows removing item from cart', async () => {
    const user = userEvent.setup();
    render(<App />);
    
    // Navigate to cart
    const cartButton = await screen.findByRole('button', { name: /cart/i });
    await user.click(cartButton);
    
    // Find and click remove button
    const removeButton = await screen.findByText('Remove');
    await user.click(removeButton);
    
    // Check if remove API was called
    const fetchCalls = fetch.mock.calls;
    const removeCall = fetchCalls.find(call => 
      call[0].includes('/cart/') && 
      call[0].includes('/item/') && 
      call[1]?.method === 'DELETE'
    );
    expect(removeCall).toBeTruthy();
  });
  
  test('displays empty cart message when cart is empty', async () => {
    // Override fetch to return empty cart
    fetch.mockImplementationOnce((url) => {
      if (url.includes('/cart') && !url.includes('/add')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve([])
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockProducts)
      });
    });
    
    const user = userEvent.setup();
    render(<App />);
    
    // Navigate to cart
    const cartButton = await screen.findByRole('button', { name: /cart/i });
    await user.click(cartButton);
    
    // Check for empty cart message
    const emptyCartMessage = await screen.findByText('Your cart is empty');
    expect(emptyCartMessage).toBeInTheDocument();
  });
  
  test('cart updates after adding product', async () => {
    const user = userEvent.setup();
    
    // Set up sequential responses for fetch
    let fetchCount = 0;
    fetch.mockImplementation(() => {
      fetchCount++;
      if (fetchCount <= 2) {  // Initial products and cart load
        return Promise.resolve({
          ok: true,
          json: () => fetchCount === 1 ? Promise.resolve(mockProducts) : Promise.resolve([])
        });
      } else if (fetchCount === 3) {  // Add to cart API call
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ success: true })
        });
      } else {  // Cart refresh after add
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve(mockCart)
        });
      }
    });
    
    render(<App />);
    
    // Find and click add to cart button
    const addToCartButtons = await screen.findAllByText('Add to Cart');
    await user.click(addToCartButtons[0]);
    
    // Navigate to cart
    const cartButton = await screen.findByRole('button', { name: /cart/i });
    await user.click(cartButton);
    
    // Check if product was added
    const diamondNecklace = await screen.findByText('Diamond Necklace');
    expect(diamondNecklace).toBeInTheDocument();
  });
});
