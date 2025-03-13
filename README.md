# Integrating Fast-response Capability into Virtual Power Plant Operation for Ancillary Services

Our paper "Integrating Fast-response Capability into Virtual Power Plant Operation for Ancillary Services" has been submitted to IEEE Powertech 2025. This repository contains the complete model (see `vpp_bidding_model.pdf`), code, and data. To run the code, you need to have MATLAB, GUROBI, and YALMIP installed.

## Overview

Virtual power plants (VPPs) can aggregate distributed energy resources (DERs) to provide ancillary services for power systems, creating new profit opportunities. Ancillary services such as frequency regulation require providers to have sufficient ramping capability to follow rapidly changing control commands. If the ramping capability requirement is overlooked, the VPP's bidding may exceed its capability, reducing its earnings in performance-based markets or risking disqualification. This paper systematically integrates the requirement for ramping capability into the operational framework of VPPs that provide ancillary services. We leverage historical control commands to formulate chance constraints in the bidding model, mandating that the VPP's ramping capability meets the needs of ancillary services with a specified probability.

## Key Scripts and Functions

### Data Preparation

- **data_prepare_main.m**: Main program for data preparation.
- **data_prepare_parameters.m**: Prepares DER parameters.
- **data_prepare_pv_output.m**: Reads PV output data.
- **data_prepare_ramp.m**: Processes ramp rate from historical RegD signals.
- **data_prepare_regd.m**: Reads and processes historical RegD signals.
- **data_prepare_std.m**: Standardizes DER performance parameters.

### Optimal Bidding Control

- **main.m**: Main program for bidding and power control.
- **main_energy.m**: Participates only in the energy market.
- **main_noRR.m**: Does not consider ramp rate constraints.
- **main_seperate_noRR.m**: Each resource participates in the market independently without ramp rate constraints.
- **fastControl_prepare.m**: Prepares parameters for the control algorithm.
- **fastControl_implement.m**: Implements the control algorithm.
- **maxProfit_1.m**: Day-ahead optimal bidding program.
- **maxProfit_t.m**: Real-time optimal bidding program.
- **profitDistribution.m**: Calculates data related to profit distribution.

### Results and Visualization

- **results_basic/**: Stores results in `.mat` format.
- **visualise/**: Contains scripts for visualizing and plotting results.
  - **cal_profit_noRR.m**: Calculates profit without ramp rate constraints.
  - **cal_profit_RR.m**: Calculates profit with ramp rate constraints.

## Getting Started

1. **Install Dependencies**: Ensure you have MATLAB, GUROBI, and YALMIP installed.
2. **Prepare Data**: Run the scripts in the `data_prepare` directory to prepare the necessary parameters and data matrices.
3. **Run Simulations**: Use the scripts in the `optimal_bidding_control` directory to perform simulations and obtain results.
4. **Visualize Results**: Use the scripts in the `visualise` directory to visualize and analyze the results.

## Contact

For any questions or issues, please contact the authors of the paper.
