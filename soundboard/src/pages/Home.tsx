import {
  IonPage,
  IonHeader,
  IonToolbar,
  IonTitle,
  IonContent,
  IonButton,
  IonInput,
  IonList,
  IonItem,
} from "@ionic/react";
import { useRef, useState } from "react";

type Sound = {
  name: string;
  url: string;
};

const Home: React.FC = () => {
  const [sounds, setSounds] = useState<Sound[]>([]);
  const [ytUrl, setYtUrl] = useState("");
  const mediaRecorder = useRef<MediaRecorder | null>(null);
  const chunks = useRef<Blob[]>([]);

  const playSound = (url: string) => {
    new Audio(url).play();
  };

  // 🔹 SUBIR AUDIO
  const uploadAudio = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const url = URL.createObjectURL(file);
    setSounds((s) => [...s, { name: file.name, url }]);
  };

  // 🔹 GRABAR AUDIO
  const startRecording = async () => {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder.current = new MediaRecorder(stream);
    chunks.current = [];

    mediaRecorder.current.ondataavailable = (e) => chunks.current.push(e.data);

    mediaRecorder.current.onstop = () => {
      const blob = new Blob(chunks.current, { type: "audio/webm" });
      const url = URL.createObjectURL(blob);
      setSounds((s) => [...s, { name: "Grabación", url }]);
    };

    mediaRecorder.current.start();
  };

  const stopRecording = () => {
    mediaRecorder.current?.stop();
  };

  // 🔹 YOUTUBE → AUDIO (API pública)
  const downloadFromYT = async () => {
    if (!ytUrl) return;
  
    const res = await fetch("http://localhost:3333/youtube", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: ytUrl }),
    });
  
    const blob = await res.blob();
    const audioUrl = URL.createObjectURL(blob);
  
    setSounds((s) => [...s, { name: "YouTube Audio", url: audioUrl }]);
    setYtUrl("");
  };
  
  

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>Soundboard</IonTitle>
        </IonToolbar>
      </IonHeader>

      <IonContent className="ion-padding">
        <IonInput
          placeholder="URL de YouTube"
          value={ytUrl}
          onIonChange={(e) => setYtUrl(e.detail.value!)}
        />
        <IonButton expand="block" onClick={downloadFromYT}>
          Añadir desde YouTube
        </IonButton>

        <IonButton expand="block" onClick={startRecording}>
          Grabar
        </IonButton>
        <IonButton expand="block" color="danger" onClick={stopRecording}>
          Parar grabación
        </IonButton>

        <input type="file" accept="audio/*" onChange={uploadAudio} />

        <IonList>
          {sounds.map((sound, i) => (
            <IonItem key={i}>
              <IonButton expand="block" onClick={() => playSound(sound.url)}>
                {sound.name}
              </IonButton>
            </IonItem>
          ))}
        </IonList>
      </IonContent>
    </IonPage>
  );
};

export default Home;
