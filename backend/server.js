import express from "express";
import cors from "cors";
import { exec } from "child_process";
import fs from "fs";
import path from "path";

const app = express();
app.use(cors());
app.use(express.json());

app.post("/youtube", (req, res) => {
  const { url } = req.body;
  if (!url) return res.status(400).send("No URL");

  const output = `audio-${Date.now()}.mp3`;

  exec(
    `yt-dlp -x --audio-format mp3 -o ${output} ${url}`,
    (err) => {
      if (err) return res.status(500).send("Error");

      res.sendFile(path.resolve(output), () => {
        fs.unlinkSync(output);
      });
    }
  );
});

app.listen(3333, () =>
  console.log("Backend local en http://localhost:3333")
);
