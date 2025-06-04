import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { useToast } from "@/components/ui/use-toast";

const Signup = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [name, setName] = useState(""); // Öğrenci/Librarian için ortak isim alanı
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // 🔧 Base URL is dynamically injected during build time
      const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";
      
      const response = await fetch(`${API_BASE_URL}/api/students/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          password,
          name,
          student_number: `STU${Math.floor(Math.random() * 10000)}`, // Basit random numara
          first_name: firstName,
          last_name: lastName,
        }),
        credentials: "include", // 🍪 Eğer session/cookie tabanlı auth varsa gerekli
      });

      if (response.ok) {
        toast({
          title: "Başarılı",
          description: "Kayıt başarılı. Giriş ekranına yönlendiriliyorsunuz.",
        });
        navigate("/login");
      } else {
        const errorData = await response.json();
        toast({
          variant: "destructive",
          title: "Kayıt Hatası",
          description: errorData?.error || "Kayıt sırasında bir hata oluştu.",
        });
      }
    } catch (error) {
      toast({
        variant: "destructive",
        title: "Bağlantı Hatası",
        description: "Sunucuya ulaşılamadı. Lütfen bağlantınızı kontrol edin.",
      });
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-r from-slate-900 to-slate-700">
      <Card className="w-full max-w-md p-8 bg-white/95 backdrop-blur-sm shadow-xl">
        <h1 className="text-3xl font-bold text-center mb-6 text-slate-800">Kayıt Ol</h1>
        <form onSubmit={handleSignup} className="space-y-4">
          <Input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
          <Input
            type="password"
            placeholder="Şifre"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <Input
            type="text"
            placeholder="Ad"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            required
          />
          <Input
            type="text"
            placeholder="Soyad"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            required
          />
          <Input
            type="text"
            placeholder="Öğrenci Adı"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />
          <Button
            type="submit"
            className="w-full bg-slate-800 hover:bg-slate-700 text-white py-6"
          >
            Kayıt Ol
          </Button>
        </form>
      </Card>
    </div>
  );
};

export default Signup;
