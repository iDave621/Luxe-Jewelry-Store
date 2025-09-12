import { render, screen, waitFor } from '@testing-library/react';
import App from './App';

// Mock fetch API to avoid actual network requests
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([])
  })
);

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn()
};
Object.defineProperty(window, 'localStorage', { value: localStorageMock });

describe('App Component', () => {
  beforeEach(() => {
    fetch.mockClear();
    localStorageMock.getItem.mockClear();
    localStorageMock.setItem.mockClear();
  });

  test('renders main application structure', async () => {
    render(<App />);
    
    // Check for main structural elements
    expect(screen.getByText(/Luxe Jewelry/i)).toBeInTheDocument();
    expect(screen.getByRole('navigation')).toBeInTheDocument();
    expect(screen.getByRole('main')).toBeInTheDocument();
    expect(screen.getByRole('contentinfo')).toBeInTheDocument(); // footer
  });

  test('fetches products on initial load', async () => {
    render(<App />);
    
    // Verify products API was called
    await waitFor(() => {
      expect(fetch).toHaveBeenCalledWith(expect.stringContaining('/products'));
    });
  });

  test('generates session ID on first visit', () => {
    // Mock localStorage to simulate first visit
    localStorageMock.getItem.mockReturnValueOnce(null);
    
    render(<App />);
    
    // Verify localStorage was checked and a new session was set
    expect(localStorageMock.getItem).toHaveBeenCalledWith('jewelry_session_id');
    expect(localStorageMock.setItem).toHaveBeenCalled();
  });

  test('uses existing session ID for returning visitors', () => {
    // Mock localStorage to simulate returning visitor
    const mockSessionId = 'session_abc123';
    localStorageMock.getItem.mockReturnValueOnce(mockSessionId);
    
    render(<App />);
    
    // Verify localStorage was checked but no new session was set
    expect(localStorageMock.getItem).toHaveBeenCalledWith('jewelry_session_id');
    expect(localStorageMock.setItem).not.toHaveBeenCalledWith('jewelry_session_id', expect.any(String));
  });

  test('renders copyright info in footer', () => {
    render(<App />);
    const copyright = screen.getByText(/© 2024 Luxe Jewelry/i);
    expect(copyright).toBeInTheDocument();
  });
});
