import tkinter as tk
from tkinter import messagebox, simpledialog
import requests
import random
import threading
import time
import logging

# Logging setup
logging.basicConfig(level=logging.DEBUG, format='[%(levelname)s] %(message)s')

MIDDLEWARE_URL = "https://alibi-myn4.onrender.com/interrogate"
VALID_ROLES = [
    "Driver", "Lookout", "Hacker", "Muscle",
    "Inside Man", "Mastermind", "Tech Specialist", "Demolitions Expert"
]

class AlibiGame:
    def __init__(self, master):
        self.master = master
        self.master.title("🎮 Alibi: Interrogation Experience")
        self.master.geometry("700x600")

        self.name = ""
        self.difficulty = "Normal"
        self.role = random.choice(VALID_ROLES)
        self.scenario = {}
        self.evidence = []
        self.conversationHistory = []  # Changed from history
        self.context = []
        self.current_question = ""
        self.time_left = 60
        self.start_time = time.time()
        self.interrogation_over = False

        self.build_intro_screen()

    def build_intro_screen(self):
        self.clear_frame()
        intro_text = (
            "🎮 WELCOME TO ALIBI: The Interrogation Experience\n\n"
            "You've been linked to a high-stakes robbery.\n"
            "Your goal is to survive questioning for 15 minutes.\n\n"
            "- The system already knows more than you think.\n"
            "- Your story must be sharp, clear, and consistent.\n"
            "- Contradict yourself, and you'll be exposed.\n\n"
            "🕒 You'll have 1 minute to answer each question.\n"
            "Last the full interrogation, and you walk free."
        )
        label = tk.Label(self.master, text=intro_text, justify="left", wraplength=650)
        label.pack(pady=20)

        start_button = tk.Button(self.master, text="Start Interrogation", command=self.get_player_info)
        start_button.pack()

    def get_player_info(self):
        self.name = simpledialog.askstring("Name", "Enter your name:")
        difficulty_choice = simpledialog.askinteger("Difficulty", "Choose difficulty:\n1. Easy\n2. Normal\n3. Hard\n4. Expert", minvalue=1, maxvalue=4)
        difficulties = {1: "Easy", 2: "Normal", 3: "Hard", 4: "Expert"}
        self.difficulty = difficulties.get(difficulty_choice, "Normal")
        self.role = random.choice(VALID_ROLES)
        self.start_interrogation(first=True)

    def start_interrogation(self, first=False, player_answer=""):
        payload = {
            "playerName": self.name,
            "role": self.role,
            "difficulty": self.difficulty,
            "conversationHistory": self.conversationHistory,  # Changed from history
            "context": self.context,
            "playerResponse": player_answer,  # Changed from playerAnswer
            "startInterrogation": first
        }

        logging.debug(f"Sending payload: {payload}")

        try:
            response = requests.post(MIDDLEWARE_URL, json=payload)
            logging.debug(f"Received status: {response.status_code}")
            logging.debug(f"Response text: {response.text}")
            response.raise_for_status()
            data = response.json()

            if first:
                self.scenario = data.get("scenario", {})
                self.evidence = data.get("evidence", [])

            self.current_question = data.get("response", "")
            self.context.append(self.current_question)
            self.build_interrogation_screen()

        except requests.exceptions.RequestException as e:
            logging.error("Interrogation setup failed.")
            messagebox.showerror("Error", str(e))

    def build_interrogation_screen(self):
        self.clear_frame()

        tk.Label(self.master, text="🚨 INTERROGATION INITIATED", font=("Helvetica", 14, "bold")).pack(pady=10)

        if self.scenario:
            scenario_text = "📂 Case Details:\n" + "\n".join([f"   - {k.capitalize()}: {v}" for k, v in self.scenario.items()])
            tk.Label(self.master, text=scenario_text, justify="left").pack(pady=5)

            evidence_text = "🧾 Evidence:\n" + "\n".join([f"   • {e}" for e in self.evidence])
            tk.Label(self.master, text=evidence_text, justify="left").pack(pady=5)

        question_text = f"❓ Question:\n   {self.current_question}"
        self.question_label = tk.Label(self.master, text=question_text, justify="left", wraplength=650)
        self.question_label.pack(pady=10)

        self.answer_entry = tk.Entry(self.master, width=80)
        self.answer_entry.pack()

        self.timer_label = tk.Label(self.master, text="Time left: 60 seconds")
        self.timer_label.pack(pady=5)

        submit_btn = tk.Button(self.master, text="Submit Answer", command=self.submit_answer)
        submit_btn.pack(pady=10)

        self.time_left = 60
        self.update_timer()

    def update_timer(self):
        self.timer_label.config(text=f"Time left: {self.time_left} seconds")
        if self.time_left > 0:
            self.time_left -= 1
            self.master.after(1000, self.update_timer)
        else:
            self.submit_answer(auto_submit=True)

    def submit_answer(self, auto_submit=False):
        answer = self.answer_entry.get() if not auto_submit else "[No Answer Submitted]"
        
        # Add to conversation history in the format the middleware expects
        self.conversationHistory.append({
            "role": "detective",
            "content": self.current_question
        })
        self.conversationHistory.append({
            "role": "player", 
            "content": answer
        })

        if time.time() - self.start_time > 15 * 60:
            self.end_interrogation()
        else:
            self.start_interrogation(first=False, player_answer=answer)

    def end_interrogation(self):
        self.clear_frame()
        tk.Label(self.master, text="✅ You survived the interrogation!", font=("Helvetica", 16, "bold")).pack(pady=20)
        tk.Button(self.master, text="Play Again", command=self.restart_game).pack(pady=10)
        tk.Button(self.master, text="Exit", command=self.master.destroy).pack(pady=5)

    def restart_game(self):
        self.name = ""
        self.difficulty = "Normal"
        self.role = random.choice(VALID_ROLES)
        self.scenario = {}
        self.evidence = []
        self.conversationHistory = []  # Changed from history
        self.context = []
        self.current_question = ""
        self.time_left = 60
        self.start_time = time.time()
        self.build_intro_screen()

    def clear_frame(self):
        for widget in self.master.winfo_children():
            widget.destroy()

root = tk.Tk()
game = AlibiGame(root)
root.mainloop() 