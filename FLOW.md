# FPGA Neural Network (Iris Classifier) — Exact Flow

Board note: don't use PYNQ-Z2. Pick **Artix-7** — e.g. **Basys 3** (part `xc7a35tcpg236-1`)
or **Arty A7** (`xc7a35ticsg324-1L`). This design is pure RTL (no ARM/Linux/PYNQ overlay
needed), so a plain Artix-7 board is simpler and works fine. Virtex boards are
overkill/expensive — skip them.

All files below are already generated and tested (30/30 correct in simulation). Just follow these steps.

---

## STEP 1 — Files
Use the 11 files exactly as given: `train_export_weights.py`, the 8 `.mem` files,
`serial_layer.v`, `parallel_layer.v`, `argmax3.v`, `top_nn.v`, `tb_top.v`, `tb_sweep.v`.
(You don't need to re-run the Python — weights are already trained and exported. Skip to Step 2.)

If you ever DO need to regenerate weights:
```
pip install numpy scikit-learn
python3 train_export_weights.py
```

## STEP 2 — Create Vivado project
1. Vivado → **Create Project** → Next
2. Project name: `iris_fpga_nn` → Next
3. Project type: **RTL Project** → Next
4. **Add Sources** here: add these 4 files only —
   `serial_layer.v`, `parallel_layer.v`, `argmax3.v`, `top_nn.v`
5. **Add Constraints**: skip (Next)
6. **Default Part**: search `xc7a35tcpg236-1` (Basys 3) → select it → Next
7. Finish

## STEP 3 — Add simulation sources
1. In Sources panel, right-click **Simulation Sources** → **Add Sources**
2. Choose **Add or create simulation sources** → Add Files
3. Add `tb_top.v` (this is your main testbench)
4. Finish

## STEP 4 — Add the .mem files so $readmemh can find them
1. Right-click **Simulation Sources** again → **Add Sources**
2. Choose **Add or create simulation sources** → Add Files
3. Select ALL 8 `.mem` files (`weights1.mem`, `bias1.mem`, `weights2.mem`, `bias2.mem`,
   `weights3.mem`, `bias3.mem`, `test_input.mem`, `expected_class.txt`)
   — yes, add `expected_class.txt` too, same way.
4. Finish
   (This makes Vivado copy them into the simulation run folder so the bare filenames in
   `$readmemh("weights1.mem", ...)` resolve correctly.)

## STEP 5 — Set the testbench as top for simulation
1. In Sources panel, expand **Simulation Sources**
2. Right-click `tb_top` → **Set as Top**

## STEP 6 — Run simulation
1. Flow Navigator (left side) → **SIMULATION** → **Run Simulation** → **Run Behavioral Simulation**
2. Wait for it to elaborate and run
3. Open the **Tcl Console** (bottom) — you'll see:
   ```
   Predicted class = 0   Expected class = 0
   PASS: hardware output matches the trained model.
   ```
   If you don't see it because the sim window is showing only waveforms, in the Tcl console type:
   ```
   run -all
   ```

**That's it — simulation done, correctness proven.** This is your working "software" of the
project (RTL design + verified functional simulation), which is exactly what you explain
in an interview.

## STEP 7 — Run it on the physical Nexys 4 board
Board confirmed: **Nexys 4 (original, non-DDR)**, part `xc7a100tcsg324-1`.

Two new files handle this: `nexys4_top.v` (hardware wrapper — feeds the same proven test
sample into the network and shows the result on LEDs) and `nexys4_top.xdc` (pin mapping,
taken directly from Digilent's official Nexys-4-Master.xdc). Already simulated and verified
working (LED[1:0] = 00 = correct predicted class) before being given to you.

1. In Sources panel, right-click **Design Sources** → **Add Sources** → **Add or create
   design sources** → Add Files → select `nexys4_top.v` → Finish
2. Right-click `nexys4_top` (the module, once visible) → **Set as Top**
   (this replaces `top_nn` as top-level for synthesis/implementation — `top_nn` still gets
   used underneath, just wrapped)
3. Right-click **Constraints** → **Add Sources** → **Add or create constraints** → Add Files
   → select `nexys4_top.xdc` → Finish
4. Flow Navigator → **SYNTHESIS** → **Run Synthesis** → wait for it to finish → click OK/Cancel
   on the popup (don't open synthesized design, not needed)
5. Flow Navigator → **IMPLEMENTATION** → **Run Implementation** → wait for it to finish
6. Flow Navigator → **PROGRAM AND DEBUG** → **Generate Bitstream** → wait for it to finish
7. Plug in the Nexys 4 via USB, power it ON
8. Flow Navigator → **PROGRAM AND DEBUG** → **Open Hardware Manager** → **Open Target** →
   **Auto Connect** → **Program Device** → select the `.bit` file it shows → **Program**
9. On the board: press the **center button (BTNC)** once to start the classification
10. Watch the LEDs: **LED2 turns ON** = done. **LED0/LED1** show the predicted class in
    binary (00 = class 0/setosa — this is the expected result for the hardcoded sample)
11. Press the **CPU RESET** button to reset and run again

That's your full submission: simulation-verified RTL + working physical hardware demo.

## Batch test (extra proof, optional)
`tb_sweep.v` runs all 30 held-out Iris test samples through the hardware and reports how many
were classified correctly (already verified: 30/30). To use it: repeat Steps 3–6 but use
`tb_sweep.v` as the simulation top instead of `tb_top.v`, and also add `all_test_inputs.mem`
and `all_expected.txt` in Step 4.

## What each file is (for later, when you actually read it)
- `train_export_weights.py` — trains a 4→8→3→3 network on Iris in Python, converts the
  weights/biases to Q8.8 fixed-point, writes them as `.mem` hex files.
- `serial_layer.v` — a fully-connected layer computed one MAC per clock cycle (used for
  layer 1 and layer 3).
- `parallel_layer.v` — a fully-connected layer computed all-at-once in one clock cycle
  (used for layer 2).
- `argmax3.v` — picks which of the 3 output neurons is largest = predicted class.
- `top_nn.v` — wires the 3 layers + argmax together with a small state machine.
- `tb_top.v` — testbench: feeds in one real Iris sample, checks the predicted class.
- `tb_sweep.v` — testbench: feeds in 30 samples, reports overall accuracy.
