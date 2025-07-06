import tkinter as tk
from tkinter import messagebox, simpledialog, ttk
import requests
import random
import threading
import time
import logging
from tkinter import font

# Logging setup
logging.basicConfig(level=logging.DEBUG, format='[%(levelname)s] %(message)s')

MIDDLEWARE_URL = "https://alibi-myn4.onrender.com/interrogate"
VALID_ROLES = [
    "Driver", "Lookout", "Hacker", "Muscle",
    "Inside Man", "Mastermind", "Tech Specialist", "Demolitions Expert"
]

class ModernButton(tk.Button):
    def __init__(self, master, **kwargs):
        super().__init__(master, **kwargs)
        self.config(
            relief="flat",
            borderwidth=0,
            font=("Segoe UI", 10, "bold"),
            cursor="hand2"
        )
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
    
    def on_enter(self, e):
        self.config(bg="#4a90e2")
    
    def on_leave(self, e):
        self.config(bg="#2c3e50")

class AlibiGame:
    def __init__(self, master):
        self.master = master
        self.master.title("🎮 ALIBI: The Interrogation Experience")
        
        # Get screen dimensions and set window size
        screen_width = self.master.winfo_screenwidth()
        screen_height = self.master.winfo_screenheight()
        window_width = min(1200, screen_width - 100)
        window_height = min(800, screen_height - 100)
        
        # Center the window
        x = (screen_width - window_width) // 2
        y = (screen_height - window_height) // 2
        self.master.geometry(f"{window_width}x{window_height}+{x}+{y}")
        self.master.resizable(True, True)
        
        # Configure grid weights for responsive design
        self.master.grid_rowconfigure(0, weight=1)
        self.master.grid_columnconfigure(0, weight=1)
        
        # Set modern colors
        self.colors = {
            'bg_dark': '#1a1a2e',
            'bg_medium': '#16213e',
            'bg_light': '#0f3460',
            'accent': '#e94560',
            'text_light': '#ffffff',
            'text_gray': '#b8b8b8',
            'success': '#00d4aa',
            'warning': '#ffa726',
            'danger': '#ef5350',
            'gradient_start': '#667eea',
            'gradient_end': '#764ba2'
        }
        
        self.master.configure(bg=self.colors['bg_dark'])
        
        # Game state
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

    def create_gradient_frame(self, parent, **kwargs):
        """Create a frame with gradient-like styling"""
        frame = tk.Frame(parent, bg=self.colors['bg_medium'], relief="flat", bd=2, **kwargs)
        return frame

    def create_modern_label(self, parent, text, **kwargs):
        """Create a modern styled label"""
        return tk.Label(parent, text=text, bg=self.colors['bg_medium'], fg=self.colors['text_light'], 
                       font=("Segoe UI", 10), **kwargs)

    def build_intro_screen(self):
        self.clear_frame()
        
        # Main container
        main_frame = self.create_gradient_frame(self.master, padx=40, pady=40)
        main_frame.grid(row=0, column=0, sticky="nsew", padx=20, pady=20)
        main_frame.grid_rowconfigure(1, weight=1)
        main_frame.grid_columnconfigure(0, weight=1)
        
        # Title with gradient effect
        title_frame = tk.Frame(main_frame, bg=self.colors['bg_medium'], height=100)
        title_frame.grid(row=0, column=0, sticky="ew", pady=(0, 30))
        title_frame.grid_columnconfigure(0, weight=1)
        
        title_label = tk.Label(title_frame, text="ALIBI", 
                              font=("Segoe UI", 36, "bold"), 
                              bg=self.colors['bg_medium'], 
                              fg=self.colors['accent'])
        title_label.grid(row=0, column=0, pady=10)
        
        subtitle_label = tk.Label(title_frame, text="The Interrogation Experience", 
                                 font=("Segoe UI", 16), 
                                 bg=self.colors['bg_medium'], 
                                 fg=self.colors['text_gray'])
        subtitle_label.grid(row=1, column=0, pady=5)
        
        # Content area
        content_frame = tk.Frame(main_frame, bg=self.colors['bg_medium'])
        content_frame.grid(row=1, column=0, sticky="nsew")
        content_frame.grid_columnconfigure(0, weight=1)
        
        # Intro text with better formatting
        intro_text = (
            "You've been linked to a high-stakes robbery.\n\n"
            "Your goal is to survive questioning for 15 minutes.\n\n"
            "⚠️  The system already knows more than you think.\n"
            "🎯  Your story must be sharp, clear, and consistent.\n"
            "🚨  Contradict yourself, and you'll be exposed.\n\n"
            "⏰  You'll have 1 minute to answer each question.\n"
            "🏆  Last the full interrogation, and you walk free."
        )
        
        intro_label = tk.Label(content_frame, text=intro_text, 
                              font=("Segoe UI", 12), 
                              bg=self.colors['bg_medium'], 
                              fg=self.colors['text_light'],
                              justify="left", wraplength=600)
        intro_label.grid(row=0, column=0, pady=30)
        
        # Start button with modern styling
        start_button = ModernButton(content_frame, text="🚀 START INTERROGATION", 
                                   command=self.get_player_info,
                                   bg=self.colors['accent'], fg=self.colors['text_light'],
                                   font=("Segoe UI", 14, "bold"),
                                   width=25, height=2)
        start_button.grid(row=1, column=0, pady=30)

    def get_player_info(self):
        # Create a modern dialog
        dialog = tk.Toplevel(self.master)
        dialog.title("Setup Interrogation")
        dialog.geometry("400x300")
        dialog.configure(bg=self.colors['bg_dark'])
        dialog.transient(self.master)
        dialog.grab_set()
        
        # Center dialog
        dialog.geometry("+%d+%d" % (self.master.winfo_rootx() + 50, self.master.winfo_rooty() + 50))
        
        # Name input
        tk.Label(dialog, text="Enter your name:", font=("Segoe UI", 12), 
                bg=self.colors['bg_dark'], fg=self.colors['text_light']).pack(pady=10)
        
        name_entry = tk.Entry(dialog, font=("Segoe UI", 12), width=30)
        name_entry.pack(pady=5)
        name_entry.focus()
        
        # Difficulty selection
        tk.Label(dialog, text="Choose difficulty:", font=("Segoe UI", 12), 
                bg=self.colors['bg_dark'], fg=self.colors['text_light']).pack(pady=10)
        
        difficulty_var = tk.StringVar(value="Normal")
        difficulties = [("Easy", "Easy"), ("Normal", "Normal"), ("Hard", "Hard"), ("Expert", "Expert")]
        
        for text, value in difficulties:
            tk.Radiobutton(dialog, text=text, variable=difficulty_var, value=value,
                          font=("Segoe UI", 10), bg=self.colors['bg_dark'], 
                          fg=self.colors['text_light'], selectcolor=self.colors['bg_medium']).pack()
        
        def on_submit():
            self.name = name_entry.get() or "Player"
            self.difficulty = difficulty_var.get()
            self.role = random.choice(VALID_ROLES)
            dialog.destroy()
            self.start_interrogation(first=True)
        
        # Submit button
        submit_btn = ModernButton(dialog, text="START", command=on_submit,
                                 bg=self.colors['accent'], fg=self.colors['text_light'],
                                 font=("Segoe UI", 12, "bold"))
        submit_btn.pack(pady=20)
        
        # Enter key binding
        name_entry.bind('<Return>', lambda e: on_submit())

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
        
        # Main container with responsive grid
        main_frame = self.create_gradient_frame(self.master)
        main_frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
        main_frame.grid_rowconfigure(1, weight=1)
        main_frame.grid_columnconfigure(0, weight=1)
        
        # Header with title and timers
        header_frame = tk.Frame(main_frame, bg=self.colors['bg_medium'], height=80)
        header_frame.grid(row=0, column=0, sticky="ew", padx=10, pady=10)
        header_frame.grid_columnconfigure(1, weight=1)
        header_frame.grid_columnconfigure(3, weight=1)
        
        # Title
        title_label = tk.Label(header_frame, text="🚨 INTERROGATION ROOM", 
                              font=("Segoe UI", 18, "bold"), 
                              bg=self.colors['bg_medium'], 
                              fg=self.colors['accent'])
        title_label.grid(row=0, column=0, sticky="w", padx=10, pady=5)
        
        # Remove total timer from header_frame
        # self.total_timer_label = tk.Label(header_frame, text="⏰ Total: 15:00", 
        #                                  font=("Segoe UI", 14, "bold"), 
        #                                  bg=self.colors['bg_medium'], 
        #                                  fg=self.colors['success'])
        # self.total_timer_label.grid(row=0, column=1, padx=10, pady=5)
        
        # Content area
        content_frame = tk.Frame(main_frame, bg=self.colors['bg_medium'])
        content_frame.grid(row=1, column=0, sticky="nsew", padx=10, pady=10)
        content_frame.grid_rowconfigure(2, weight=1)
        content_frame.grid_columnconfigure(0, weight=1)
        
        # Scenario and evidence section
        if self.scenario:
            info_frame = tk.Frame(content_frame, bg=self.colors['bg_light'], relief="flat", bd=1)
            info_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))
            info_frame.grid_columnconfigure(0, weight=1)
            
            # Scenario details
            scenario_text = "📂 CASE DETAILS"
            scenario_label = tk.Label(info_frame, text=scenario_text, 
                                     font=("Segoe UI", 12, "bold"), 
                                     bg=self.colors['bg_light'], 
                                     fg=self.colors['accent'])
            scenario_label.grid(row=0, column=0, sticky="w", padx=10, pady=5)
            
            details_text = "\n".join([f"   • {k.capitalize()}: {v}" for k, v in self.scenario.items()])
            details_label = tk.Label(info_frame, text=details_text, 
                                    font=("Segoe UI", 10), 
                                    bg=self.colors['bg_light'], 
                                    fg=self.colors['text_light'],
                                    justify="left")
            details_label.grid(row=1, column=0, sticky="w", padx=20, pady=5)
            
            # Evidence
            evidence_text = "🧾 EVIDENCE AGAINST YOU"
            evidence_title = tk.Label(info_frame, text=evidence_text, 
                                     font=("Segoe UI", 12, "bold"), 
                                     bg=self.colors['bg_light'], 
                                     fg=self.colors['danger'])
            evidence_title.grid(row=2, column=0, sticky="w", padx=10, pady=(15, 5))
            
            evidence_list = "\n".join([f"   • {e}" for e in self.evidence])
            evidence_label = tk.Label(info_frame, text=evidence_list, 
                                     font=("Segoe UI", 10), 
                                     bg=self.colors['bg_light'], 
                                     fg=self.colors['text_gray'],
                                     justify="left")
            evidence_label.grid(row=3, column=0, sticky="w", padx=20, pady=5)
        
        # Question section
        question_frame = tk.Frame(content_frame, bg=self.colors['bg_light'], relief="flat", bd=1)
        question_frame.grid(row=1, column=0, sticky="ew", pady=10)
        question_frame.grid_columnconfigure(0, weight=1)
        question_frame.grid_columnconfigure(1, weight=0)
        
        # Question title and response timer in same row
        question_title = tk.Label(question_frame, text="❓ DETECTIVE'S QUESTION", 
                                 font=("Segoe UI", 12, "bold"), 
                                 bg=self.colors['bg_light'], 
                                 fg=self.colors['accent'])
        question_title.grid(row=0, column=0, sticky="w", padx=10, pady=5)
        
        # Remove response timer from question_frame
        # self.response_timer_label = tk.Label(question_frame, text="⚡ Response: 60s", 
        #                                    font=("Segoe UI", 12, "bold"), 
        #                                    bg=self.colors['bg_light'], 
        #                                    fg=self.colors['warning'])
        # self.response_timer_label.grid(row=0, column=1, sticky="e", padx=10, pady=5)
        
        self.question_label = tk.Label(question_frame, text=self.current_question, 
                                      font=("Segoe UI", 11), 
                                      bg=self.colors['bg_light'], 
                                      fg=self.colors['text_light'],
                                      justify="left", wraplength=800)
        self.question_label.grid(row=1, column=0, columnspan=2, sticky="w", padx=20, pady=10)
        
        # Answer section
        answer_frame = tk.Frame(content_frame, bg=self.colors['bg_light'], relief="flat", bd=1)
        answer_frame.grid(row=2, column=0, sticky="ew", pady=10)
        answer_frame.grid_columnconfigure(0, weight=1)
        
        answer_title = tk.Label(answer_frame, text="💬 YOUR RESPONSE", 
                               font=("Segoe UI", 12, "bold"), 
                               bg=self.colors['bg_light'], 
                               fg=self.colors['success'])
        answer_title.grid(row=0, column=0, sticky="w", padx=10, pady=5)
        
        self.answer_entry = tk.Entry(answer_frame, font=("Segoe UI", 12), 
                                    bg=self.colors['bg_dark'], fg=self.colors['text_light'],
                                    insertbackground=self.colors['text_light'],
                                    relief="flat", bd=5)
        self.answer_entry.grid(row=1, column=0, sticky="ew", padx=20, pady=10)
        
        # Add timers in a horizontal row below answer_entry
        timers_frame = tk.Frame(answer_frame, bg=self.colors['bg_light'])
        timers_frame.grid(row=2, column=0, sticky="w", padx=10, pady=5)
        self.response_timer_label = tk.Label(timers_frame, text="⚡ Response: 60s", 
                                            font=("Segoe UI", 12, "bold"), 
                                            bg=self.colors['bg_light'], 
                                            fg=self.colors['warning'])
        self.response_timer_label.pack(side="left", padx=(0, 20))
        self.total_timer_label = tk.Label(timers_frame, text="⏰ Total: 15:00", 
                                         font=("Segoe UI", 12, "bold"), 
                                         bg=self.colors['bg_light'], 
                                         fg=self.colors['success'])
        self.total_timer_label.pack(side="left")
        
        # Submit button
        submit_btn = ModernButton(answer_frame, text="🚀 SUBMIT ANSWER", 
                                 command=self.submit_answer,
                                 bg=self.colors['accent'], fg=self.colors['text_light'],
                                 font=("Segoe UI", 12, "bold"),
                                 width=20, height=2)
        submit_btn.grid(row=3, column=0, pady=15)
        
        # Only show waiting message for first question
        if self.is_first_question:
            self.response_timer_label.config(text="⚡ Response: Waiting for first answer...", fg=self.colors['text_gray'])

    def start_response_timer(self):
        # Cancel any existing timer
        if hasattr(self, '_response_timer_id'):
            self.master.after_cancel(self._response_timer_id)
        
        if self.response_timer_running:
            return
            
        self.response_timer_running = True
        self.response_time_left = 60
        
        def update_response_timer():
            if self.interrogation_over or not self.response_timer_running:
                return
                
            if self.response_time_left > 0:
                color = self.colors['success'] if self.response_time_left > 30 else self.colors['warning'] if self.response_time_left > 10 else self.colors['danger']
                self.response_timer_label.config(text=f"⚡ Response: {self.response_time_left}s", fg=color)
                self.response_time_left -= 1
                self._response_timer_id = self.master.after(1000, update_response_timer)
            else:
                self.response_timer_running = False
                self.submit_answer(auto_submit=True)
        
        update_response_timer()

    def start_total_timer(self):
        # Cancel any existing timer
        if hasattr(self, '_total_timer_id'):
            self.master.after_cancel(self._total_timer_id)
            
        if self.timer_running:
            return
            
        self.timer_running = True
        
        def update_total_timer():
            if self.interrogation_over or not self.timer_running:
                return
                
            if self.total_time_left > 0:
                minutes = self.total_time_left // 60
                seconds = self.total_time_left % 60
                color = self.colors['success'] if self.total_time_left > 300 else self.colors['warning'] if self.total_time_left > 60 else self.colors['danger']
                self.total_timer_label.config(text=f"⏰ Total: {minutes:02d}:{seconds:02d}", fg=color)
                self.total_time_left -= 1
                self._total_timer_id = self.master.after(1000, update_total_timer)
            else:
                self.timer_running = False
                self.end_interrogation(player_won=True)
        
        update_total_timer()

    def submit_answer(self, auto_submit=False):
        answer = self.answer_entry.get() if not auto_submit else "[No Answer Submitted]"
        
        # Clear the input field
        self.answer_entry.delete(0, tk.END)
        
        # Stop response timer
        self.response_timer_running = False
        
        # Add to conversation history in the correct format
        if not auto_submit:  # Only add if it's a real answer, not auto-submit
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

        # Show loading message
        self.question_label.config(text="🔄 Getting AI response...", fg=self.colors['warning'])

        # Get AI response
        try:
            payload = {
                "playerName": self.name,
                "role": self.role,
                "difficulty": self.difficulty,
                "conversationHistory": self.conversationHistory,
                "context": self.context,
                "playerResponse": answer,
                "startInterrogation": False
            }
            logging.debug(f"Sending payload: {payload}")
            response = requests.post(MIDDLEWARE_URL, json=payload, timeout=30)
            
            logging.debug(f"Response status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                ai_response = data.get("response", "")
                logging.debug(f"AI response: {ai_response}")
                
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
                        logging.debug(f"AI caught player with phrase: {phrase}")
                        self.end_interrogation(ai_caught=True)
                        return
                
                # If not caught, continue with normal flow
                self.current_question = ai_response
                self.context.append(self.current_question)
                self.build_interrogation_screen()
                
                # Start timers for the next question
                if not self.timer_running:
                    self.start_total_timer()
                self.start_response_timer()  # Always restart response timer for new question
            else:
                logging.error(f"HTTP error: {response.status_code}")
                try:
                    error_data = response.json()
                    error_message = error_data.get('error', 'Unknown error')
                    logging.error(f"Error details: {error_data}")
                    
                    # If session not found, try to restart
                    if "Session not found" in error_message:
                        logging.info("Session lost, restarting interrogation...")
                        self.conversationHistory = []
                        self.context = []
                        self.start_interrogation(first=True)
                        return
                    else:
                        messagebox.showerror("Error", f"Failed to get AI response: {error_message}")
                except:
                    messagebox.showerror("Error", f"Failed to get AI response (HTTP {response.status_code})")
                
        except requests.exceptions.Timeout:
            logging.error("Request timeout")
            messagebox.showerror("Error", "Request timed out. Please try again.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Request failed: {e}")
            messagebox.showerror("Error", f"Failed to get AI response: {str(e)}")
        except Exception as e:
            logging.error(f"Unexpected error: {e}")
            messagebox.showerror("Error", f"Unexpected error: {str(e)}")

    def end_interrogation(self, player_won=False, ai_caught=False):
        self.interrogation_over = True
        self.timer_running = False
        self.response_timer_running = False
        
        self.clear_frame()
        
        # Main result container
        result_frame = self.create_gradient_frame(self.master, padx=60, pady=60)
        result_frame.grid(row=0, column=0, sticky="nsew", padx=40, pady=40)
        result_frame.grid_rowconfigure(1, weight=1)
        result_frame.grid_columnconfigure(0, weight=1)
        
        if ai_caught:
            title = "🚨 CAUGHT BY AI!"
            message = "The AI detective has caught you in a lie!\n\nYou've been exposed and arrested."
            color = self.colors['danger']
            icon = "🚨"
        elif player_won:
            title = "✅ INTERROGATION SURVIVED!"
            message = "Congratulations! You've survived the full 15-minute interrogation.\n\nYou walk free!"
            color = self.colors['success']
            icon = "🏆"
        else:
            title = "⏰ TIME'S UP!"
            message = "You ran out of time to answer.\n\nThe interrogation continues..."
            color = self.colors['warning']
            icon = "⏰"
        
        # Result icon and title
        icon_label = tk.Label(result_frame, text=icon, font=("Segoe UI", 48), 
                             bg=self.colors['bg_medium'], fg=color)
        icon_label.grid(row=0, column=0, pady=20)
        
        result_label = tk.Label(result_frame, text=title, 
                               font=("Segoe UI", 24, "bold"), 
                               bg=self.colors['bg_medium'], fg=color)
        result_label.grid(row=1, column=0, pady=10)
        
        message_label = tk.Label(result_frame, text=message, 
                                font=("Segoe UI", 14), 
                                bg=self.colors['bg_medium'], 
                                fg=self.colors['text_light'],
                                wraplength=500, justify="center")
        message_label.grid(row=2, column=0, pady=20)
        
        # Buttons
        button_frame = tk.Frame(result_frame, bg=self.colors['bg_medium'])
        button_frame.grid(row=3, column=0, pady=20)
        
        play_again_btn = ModernButton(button_frame, text="🔄 PLAY AGAIN", 
                                     command=self.restart_game,
                                     bg=self.colors['accent'], fg=self.colors['text_light'],
                                     font=("Segoe UI", 12, "bold"))
        play_again_btn.pack(side="left", padx=10)
        
        exit_btn = ModernButton(button_frame, text="🚪 EXIT", 
                               command=self.master.destroy,
                               bg=self.colors['bg_light'], fg=self.colors['text_light'],
                               font=("Segoe UI", 12, "bold"))
        exit_btn.pack(side="left", padx=10)

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