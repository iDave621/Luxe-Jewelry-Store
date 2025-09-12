import { render, screen } from '@testing-library/react';
import App from '../App';
import userEvent from '@testing-library/user-event';

// Mock product data
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

// Mock fetch API
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve(mockProducts)
  })
);

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(() => 'test_session_id'),
  setItem: jest.fn(),
  removeItem: jest.fn()
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

describe('Products View Component', () => {
  beforeEach(() => {
    // Reset mocks
    fetch.mockClear();
    localStorageMock.getItem.mockClear();
    localStorageMock.setItem.mockClear();
  });
  
  test('renders products from API', async () => {
    render(<App />);
    
    // Verify API was called
    expect(fetch).toHaveBeenCalledTimes(2); // Products and cart fetches
    
    // Wait for products to appear
    const diamondNecklace = await screen.findByText('Diamond Necklace');
    const goldBracelet = await screen.findByText('Gold Bracelet');
    
    // Check if products are rendered
    expect(diamondNecklace).toBeInTheDocument();
    expect(goldBracelet).toBeInTheDocument();
    
    // Check if prices are rendered
    expect(screen.getByText('$2999.99')).toBeInTheDocument();
    expect(screen.getByText('$1299.99')).toBeInTheDocument();
  });
  
  test('allows navigation to products page', async () => {
    const user = userEvent.setup();
    render(<App />);
    
    // Find and click products navigation button
    const productsButton = await screen.findByRole('button', { name: /products/i });
    await user.click(productsButton);
    
    // Check if we're on products page
    const collectionHeading = await screen.findByText('Our Collection');
    expect(collectionHeading).toBeInTheDocument();
  });
  
  test('adds product to cart when "Add to Cart" is clicked', async () => {
    const user = userEvent.setup();
    
    // Mock successful add to cart API response
    fetch.mockImplementation((url) => {
      if (url.includes('/cart/')) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ success: true })
        });
      }
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockProducts)
      });
    });
    
    render(<App />);
    
    // Wait for products to appear
    const addToCartButtons = await screen.findAllByText('Add to Cart');
    
    // Click first "Add to Cart" button
    await user.click(addToCartButtons[0]);
    
    // Check if add to cart API was called
    const fetchCalls = fetch.mock.calls;
    const addToCartCall = fetchCalls.find(call => call[0].includes('/cart/') && call[0].includes('/add'));
    expect(addToCartCall).toBeTruthy();
  });
});
