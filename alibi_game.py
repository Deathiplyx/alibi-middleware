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
        self.conversationHistory = []
        self.context = []
        self.current_question = ""
        self.response_time_left = 60
        self.total_time_left = 15 * 60  # 15 minutes in seconds
        self.start_time = time.time()
        self.interrogation_over = False
        self.is_first_question = True
        self.timer_running = False
        self.response_timer_running = False

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
            "conversationHistory": self.conversationHistory,
            "context": self.context,
            "playerResponse": player_answer,
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

        # Timer labels
        self.total_timer_label = tk.Label(self.master, text="Total Time: 15:00", font=("Helvetica", 12, "bold"))
        self.total_timer_label.pack(pady=5)
        
        self.response_timer_label = tk.Label(self.master, text="Response Time: 60s", font=("Helvetica", 12))
        self.response_timer_label.pack(pady=5)

        submit_btn = tk.Button(self.master, text="Submit Answer", command=self.submit_answer)
        submit_btn.pack(pady=10)

        # Only show waiting message for first question
        if self.is_first_question:
            self.response_timer_label.config(text="Response Time: Waiting for first answer...")

    def start_response_timer(self):
        if self.response_timer_running:
            return
        self.response_timer_running = True
        
        def update_response_timer():
            if self.interrogation_over or not self.response_timer_running:
                return
                
            if self.response_time_left > 0:
                self.response_timer_label.config(text=f"Response Time: {self.response_time_left}s")
                self.response_time_left -= 1
                self.master.after(1000, update_response_timer)
            else:
                self.response_timer_running = False
                self.submit_answer(auto_submit=True)
        
        update_response_timer()

    def start_total_timer(self):
        if self.timer_running:
            return
        self.timer_running = True
        
        def update_total_timer():
            if self.interrogation_over or not self.timer_running:
                return
                
            if self.total_time_left > 0:
                minutes = self.total_time_left // 60
                seconds = self.total_time_left % 60
                self.total_timer_label.config(text=f"Total Time: {minutes:02d}:{seconds:02d}")
                self.total_time_left -= 1
                self.master.after(1000, update_total_timer)
            else:
                self.timer_running = False
                self.end_interrogation(player_won=True)
        
        update_total_timer()

    def submit_answer(self, auto_submit=False):
        answer = self.answer_entry.get() if not auto_submit else "[No Answer Submitted]"
        
        # Stop response timer
        self.response_timer_running = False
        
        # Add to conversation history
        self.conversationHistory.append({
            "role": "detective",
            "content": self.current_question
        })
        self.conversationHistory.append({
            "role": "player", 
            "content": answer
        })

        # Mark that we're no longer on the first question
        self.is_first_question = False

        # Get AI response
        try:
            response = requests.post(MIDDLEWARE_URL, json={
                "playerName": self.name,
                "role": self.role,
                "difficulty": self.difficulty,
                "conversationHistory": self.conversationHistory,
                "context": self.context,
                "playerResponse": answer,
                "startInterrogation": False
            })
            
            if response.status_code == 200:
                data = response.json()
                ai_response = data.get("response", "")
                
                # Check if AI has caught the player in a lie
                catch_phrases = [
                    "caught you", "lying", "contradiction", "guilty", "confess", 
                    "admit", "proven", "confirmed", "definitely", "clearly",
                    "definitive", "conclusive", "irrefutable", "undeniable", 
                    "caught red-handed", "beyond doubt", "proven guilty",
                    "you're under arrest", "case closed", "evidence is clear",
                    "no more lies", "we have you", "it's over"
                ]
                
                ai_response_lower = ai_response.lower()
                for phrase in catch_phrases:
                    if phrase in ai_response_lower:
                        self.end_interrogation(ai_caught=True)
                        return
                
                # If not caught, continue with normal flow
                self.current_question = ai_response
                self.context.append(self.current_question)
                self.build_interrogation_screen()
                
                # Start timers for the next question (only if not already running)
                if not self.timer_running:
                    self.start_total_timer()
                if not self.response_timer_running:
                    self.response_time_left = 60
                    self.start_response_timer()
            else:
                messagebox.showerror("Error", "Failed to get AI response")
                
        except requests.exceptions.RequestException as e:
            logging.error("Failed to get AI response")
            messagebox.showerror("Error", str(e))

    def end_interrogation(self, player_won=False, ai_caught=False):
        self.interrogation_over = True
        self.timer_running = False
        self.response_timer_running = False
        
        self.clear_frame()
        
        if ai_caught:
            title = "🚨 CAUGHT BY AI!"
            message = "The AI detective has caught you in a lie!\n\nYou've been exposed and arrested."
            color = "red"
        elif player_won:
            title = "✅ INTERROGATION SURVIVED!"
            message = "Congratulations! You've survived the full 15-minute interrogation.\n\nYou walk free!"
            color = "green"
        else:
            title = "⏰ TIME'S UP!"
            message = "You ran out of time to answer.\n\nThe interrogation continues..."
            color = "orange"
        
        result_label = tk.Label(self.master, text=title, font=("Helvetica", 16, "bold"), fg=color)
        result_label.pack(pady=20)
        
        message_label = tk.Label(self.master, text=message, font=("Helvetica", 12), wraplength=500)
        message_label.pack(pady=10)
        
        tk.Button(self.master, text="Play Again", command=self.restart_game).pack(pady=10)
        tk.Button(self.master, text="Exit", command=self.master.destroy).pack(pady=5)

    def restart_game(self):
        self.name = ""
        self.difficulty = "Normal"
        self.role = random.choice(VALID_ROLES)
        self.scenario = {}
        self.evidence = []
        self.conversationHistory = []
        self.context = []
        self.current_question = ""
        self.response_time_left = 60
        self.total_time_left = 15 * 60
        self.start_time = time.time()
        self.interrogation_over = False
        self.is_first_question = True
        self.timer_running = False
        self.response_timer_running = False
        self.build_intro_screen()

    def clear_frame(self):
        for widget in self.master.winfo_children():
            widget.destroy()

root = tk.Tk()
game = AlibiGame(root)
root.mainloop() 