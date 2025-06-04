import { Link, useLocation, useNavigate } from "react-router-dom";
import { Button } from "./ui/button";
import { useToast } from "./ui/use-toast";

const Navbar = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { toast } = useToast();
  const userRole = localStorage.getItem('userRole');
  
  const isActive = (path: string) => {
    return location.pathname === path ? "bg-slate-700" : "";
  };
  const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
  const handleLogout = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/logout/`, {
        method: 'POST',
        headers: {
          'Authorization': `Token ${localStorage.getItem('token')}`,
        },
      });

      if (response.ok) {
        localStorage.removeItem('token');
        localStorage.removeItem('userRole');
        toast({
          title: "Başarılı",
          description: "Çıkış yapıldı",
        });
        navigate('/login');
      }
    } catch (error) {
      console.error('Logout error:', error);
      toast({
        variant: "destructive",
        title: "Hata",
        description: "Çıkış yapılırken bir hata oluştu",
      });
    }
  };

  // Role-based menu items
  const getMenuItems = () => {
    const items = [];
    
    if (userRole === 'admin') {
      items.push(
        { path: '/books', label: 'Kitaplar' },
        { path: '/students', label: 'Öğrenciler' },
        { path: '/loans', label: 'Ödünç İşlemleri' }
      );
    } else if (userRole === 'student') {
      items.push(
        { path: '/books', label: 'Kitaplar' },
        { path: '/loans', label: 'Ödünç Aldıklarım' }
      );
    }
    if (userRole === 'librarian') {
      items.push(
        { path: '/books', label: 'Kitaplar' },
        { path: '/students', label: 'Öğrenciler' },
        { path: '/loans', label: 'Ödünç İşlemleri' }
      );
    }
    return items;
  };

  const menuItems = getMenuItems();

  return (
    <nav className="bg-slate-800 text-white shadow-lg">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="text-xl font-bold">
            Kütüphane Sistemi
          </Link>
          
          <div className="flex items-center space-x-4">
            <div className="flex space-x-4">
              {menuItems.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`px-3 py-2 rounded-md text-sm font-medium hover:bg-slate-700 transition-colors ${isActive(item.path)}`}
                >
                  {item.label}
                </Link>
              ))}
            </div>
            
            <Button
              onClick={handleLogout}
              variant="destructive"
              className="ml-4"
            >
              Çıkış Yap
            </Button>
          </div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;