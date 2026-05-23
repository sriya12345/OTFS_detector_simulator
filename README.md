# Overview of Components
## 1. Top-level execution
→ top-level entry: set params, run, plot
## 2. Parameter configuration
→ returns a struct of all parameters
## 3. Transmitter operations
→ random bits → QAM symbols in DD grid  
→ DD → TF → time (ISFFT + Heisenberg)  
→ CP / RCP / ZP / no-prefix dispatcher  
## 4. Channel modeling and application
→ taps: {h_i, l_i, k_i} delay-Doppler paths  
→ time-domain convolution + AWGN  
→ constructs H_eff (MN × MN) in DD domain  
→ — variant-aware (CP/RCP/ZP)
## 5. Receiver processing
→ remove prefix  
→ time → TF → DD (Wigner + SFFT)
## 6. Detection algorithms
→ documents the common signature  
→ message passing (Raviteja-style)  
→ small N only, for benchmarking  
→ (room for: AMP, EP, GAMP, deep-learning ones later)
## 7. Utility functions
→ qam_mod / qam_demod  
→ compute_ber / compute_ser  
→ snr_to_n0  
→ seed_rng  
## 8. Results storage
→ (saved .mat files, figures)
