import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { useNavigate } from "react-router-dom";

const Index = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container py-8">
  
         <div className="flex justify-center mb-8">
          <img src="/og-image.png" alt="Kütüphane Yönetim Sistemi" className="max-w-full h-auto" />
        </div>
      
      </div>
    </div>
  );
};

export default Index;