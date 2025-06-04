 import { useState } from "react";
 import { useNavigate } from "react-router-dom";
 import { Button } from "@/components/ui/button";
 import { Input } from "@/components/ui/input";
 import { Card } from "@/components/ui/card";
 import { useToast } from "@/components/ui/use-toast";
 
 const Login = () => {
   const [email, setEmail] = useState("");
   const [password, setPassword] = useState("");
   const navigate = useNavigate();
   const { toast } = useToast();
 
   const handleLogin = async (e: React.FormEvent) => {
     e.preventDefault();
     try {
       console.log("Giriş denemesi:", { email, password });
 
       const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";
 
       const response = await fetch(`${API_BASE_URL}/api/auth/login/`, {
         method: "POST",
         headers: {
           "Content-Type": "application/json"
         },
         body: JSON.stringify({ email, password }),
         credentials: "include"
       });
 
       console.log("Giriş yanıtı durumu:", response.status);
 
       if (response.ok) {
         const data = await response.json();
         console.log("Giriş başarılı, alınan veri:", data);
 
         localStorage.setItem("token", data.token);
         localStorage.setItem("userRole", data.role);
 
         toast({
           title: "Başarılı",
           description: "Giriş yapıldı"
         });
 
         navigate("/");
       } else {
         const errorData = await response.json();
         console.error("Giriş hatası:", errorData);
 
         toast({
           variant: "destructive",
           title: "Hata",
           description: errorData.error || "Email veya şifre hatalı"
         });
       }
     } catch (error) {
       console.error("Bağlantı hatası:", error);
       toast({
         variant: "destructive",
         title: "Bağlantı Hatası",
         description: "Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin."
       });
     }
   };
 
   return (
     <div className="min-h-screen flex items-center justify-center bg-gradient-to-r from-slate-900 to-slate-700">
       <Card className="w-full max-w-md p-8 bg-white/95 backdrop-blur-sm shadow-xl">
         <h1 className="text-3xl font-bold text-center mb-6 text-slate-800">Giriş Yap</h1>
         <form onSubmit={handleLogin} className="space-y-4">
           <div>
             <label htmlFor="email" className="block text-lg font-medium text-slate-700">
               Email
             </label>
             <Input
               id="email"
               type="email"
               value={email}
               onChange={(e) => setEmail(e.target.value)}
               required
               className="mt-1 text-lg bg-slate-50 border-slate-300"
             />
           </div>
           <div>
             <label htmlFor="password" className="block text-lg font-medium text-slate-700">
               Şifre
             </label>
             <Input
               id="password"
               type="password"
               value={password}
               onChange={(e) => setPassword(e.target.value)}
               required
               className="mt-1 text-lg bg-slate-50 border-slate-300"
             />
           </div>
           <Button type="submit" className="w-full bg-slate-800 hover:bg-slate-700 text-white text-lg py-6">
             Giriş Yap
           </Button>
           <div className="text-center mt-4">
             <Button
               variant="link"
               onClick={() => navigate("/signup")}
               className="text-lg text-slate-600 hover:text-slate-800"
             >
               Hesabınız yok mu? Kayıt olun--------*
             </Button>
           </div>
         </form>
       </Card>
     </div>
   );
 };
 
 export default Login;
 