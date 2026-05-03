# 🚀 The AI Vengers

## 📌 Table of Contents
- [Introduction](#introduction)
- [Demo](#demo)
- [Inspiration](#inspiration)
- [What It Does](#what-it-does)
- [How We Built It](#how-we-built-it)
- [Challenges We Faced](#challenges-we-faced)
- [How to Run](#how-to-run)
- [Tech Stack](#tech-stack)
- [Team](#team)

---

## 🎯 Introduction
The AI Vengers is an Integrated Platform Environment (IPE) designed for platform support teams. It incorporates **LLMs, agentic capabilities, and contextual recommendations** to streamline platform management and automate workflows.

## 🎥 Demo
🔗 [Live Demo](#) (if applicable)  
📹 [Video Demo](#) (if applicable)  
🖼️ Screenshots:

![Screenshot 1](link-to-image)

## 💡 Inspiration
Managing large-scale platform operations requires **fast troubleshooting and automation** to reduce downtime. Our inspiration was to build an **AI-driven assistant** that understands platform issues, suggests actions, and can even execute predefined workflows autonomously.

## ⚙️ What It Does
- Uses **Mistral-7B-Instruct-v0.1** for **context-aware decision-making**.
- Provides **real-time server status monitoring**.
- Enables **agent-driven automation**, including server restarts.
- Supports **chat-based interactions** for troubleshooting.
- Integrates with **MCP Server** for task execution.

## 🛠️ How We Built It
- **LLM:** Mistral-7B-Instruct-v0.1
- **Frameworks:** LangChain, LangGraph for agent workflow orchestration
- **Backend:** FastAPI
- **Frontend:** Streamlit
- **Deployment:** Docker, MCP Server integration

## 🚧 Challenges We Faced
- Fine-tuning agent behavior for effective tool use.
- Integrating LLM-driven contextual understanding.
- Handling API rate limits and performance optimization.

## 🏃 How to Run
1. Clone the repository  
   ```sh
   git clone https://github.com/ewfx/gaipl-the-ai-vengers.git
   cd gaipl-the-ai-vengers
   ```
2. Build and run the Docker container  
   ```sh
   docker build -t ai-vengers .
   docker run -p 8501:8501 ai-vengers
   ```
3. Access the app in your browser at  
   ```
   http://localhost:8501
   ```

## 🏗️ Tech Stack
- **LLM:** Mistral-7B-Instruct-v0.1
- **Backend:** FastAPI, LangChain, LangGraph
- **Frontend:** Streamlit
- **Deployment:** Docker, MCP Server

## 👥 Team
- **Jagannathan VS** - [GitHub](#) | [LinkedIn](#)
- **Suneel Gandham** - [GitHub](#) | [LinkedIn](#)
