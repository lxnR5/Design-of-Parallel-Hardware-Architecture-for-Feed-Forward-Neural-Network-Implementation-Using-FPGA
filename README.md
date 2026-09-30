# Design of Parallel Hardware Architecture for Feed Forward Neural Network Implementation Using FPGA

## 📌 Overview

This project presents the design and FPGA implementation of a **Feed Forward Neural Network (FFNN)** for handwritten digit classification using the **MNIST dataset**.

The neural network is first trained in software using **Python, TensorFlow, and Keras**. The trained weights and biases are then converted from floating-point representation to **fixed-point representation** and implemented using **Verilog HDL**.

The final RTL design is synthesized and implemented using **Xilinx Vivado** for the **Nexys 4 development board based on the Artix-7 FPGA**.

---

## 🔄 Project Workflow

```text
              MNIST Dataset
                    │
                    ▼
          28 × 28 Grayscale Image
                    │
                    ▼
           784-Element Input Vector
                    │
                    ▼
             FFNN 784–32–10
                    │
                    ▼
       Python / TensorFlow / Keras
                    │
                    ▼
          Neural Network Training
                    │
                    ▼
          Weight & Bias Extraction
                    │
                    ▼
            Fixed-Point Conversion
                    │
                    ▼
              Verilog HDL RTL
                    │
                    ▼
             Xilinx Vivado
                    │
                    ▼
          Nexys 4 / Artix-7 FPGA
                    │
                    ▼
             Predicted Digit
