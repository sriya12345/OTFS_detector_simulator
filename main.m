%% OTFS Detector Simulator

%% Params
N = 64;
M = 4;
MN = N*M;
M_mod = 4;
M_bits = log2(M_mod);
eng_sqrt = (M_mod==2) + (M_mod~=2)*sqrt((M_mod-1)/6*(2^2));

BandWidth = 2e6;
TdMax = 0.5e-6;
length_cp = ceil(TdMax*BandWidth);
data_grid = ones(M,N);
N_syms_perfram = sum(data_grid(:));
N_bits_perfram = N_syms_perfram * M_bits;

car_fre = 18e9; delta_f = BandWidth/M; T = 1/delta_f;

SNR_dB = 0:5:25;
SNR = 10.^(SNR_dB/10);
sigma_2 = (abs(eng_sqrt)^2) ./ SNR;

N_fram = 10;
seedGen = 1:50:5000;

%% Switches — detector-focused only
VariantList    = ["CP","RCP"];
ModulationList = "OTFS";
DetectionList  = ["LMMSE","MRC","MP"];

%% DFTs
Fn = dftmtx(N); Fn = Fn./norm(Fn);
Fm = dftmtx(M); Fm = Fm./norm(Fm);

%% Storage
curveCount = 0;
curveLabels = {};
BER_curves = {};
FER_curves = {};

%% Sweep
for Modulation = ModulationList
  for Variant = VariantList
    for Detection = DetectionList

      curveCount = curveCount + 1;
      err_ber = zeros(1,length(SNR_dB)); avg_ber = zeros(1,length(SNR_dB));
      err_fer = zeros(1,length(SNR_dB)); avg_fer = zeros(1,length(SNR_dB));

      for iesn0 = 1:length(SNR_dB)
        frameCounter = 0;
        for a = 1:length(seedGen)
          seed = seedGen(a);
          for ifram = 1:N_fram
            frameCounter = frameCounter + 1;

            % --- TX ---
            trans_info_bit = randi([0,1], N_bits_perfram, 1);
            data = qammod(reshape(trans_info_bit, M_bits, N_syms_perfram), ...
                          M_mod, 'gray', 'InputType','bit');
            X = Generate_2D_data_grid(N, M, data, data_grid);

            switch Modulation
              case 'OTFS', X_tilda = X * Fn';
              case 'OFDM', X_tilda = Fm' * X;
            end
            s = reshape(X_tilda, MN, 1);
            noiseVar = sigma_2(iesn0);

            % --- Channel ---
            max_speed = 12000;
            [chan_coef, delay_taps, Doppler_taps, taps] = ...
              Generate_delay_Doppler_channel_parameters(N,M,car_fre,delta_f,T,max_speed,seed,1);

            L_set = unique(delay_taps);
            Lmax = max(delay_taps);
            % ... build G_true and gs_true exactly as your existing CP/RCP switch does ...

            % --- Channel output ---
            r = G_true * s;
            noise = sqrt(noiseVar/2)*(randn(size(r))+1i*randn(size(r)));
            r = r + noise;

            % --- Demodulation ---
            Y_tilda = reshape(r, M, N);
            switch Modulation
              case 'OTFS', Y = Y_tilda * Fn;
              case 'OFDM', Y = Fm * Y_tilda;
            end

            % --- Perfect CSI ---
            G_used = G_true; gs_used = gs_true;

            % --- Detection (your existing dispatch block, unchanged) ---
            % LMMSE / MRC / MP branches go here

            % --- Error count ---
            errors = sum(xor(estBits, trans_info_bit));
            err_ber(iesn0) = err_ber(iesn0) + errors;
            avg_ber(iesn0) = err_ber(iesn0)/length(trans_info_bit)/frameCounter;
            if any(estBits ~= trans_info_bit)
              err_fer(iesn0) = err_fer(iesn0) + 1;
            end
            avg_fer(iesn0) = err_fer(iesn0)/frameCounter;
          end
        end
      end

      BER_curves{curveCount} = avg_ber;
      FER_curves{curveCount} = avg_fer;
      curveLabels{curveCount} = sprintf('%s | %s | %s', ...
        char(Modulation), char(Variant), char(Detection));
    end
  end
end