CORE := qspi_master

DEPS_qspi_master = no2misc no2ice40

RTL_SRCS_qspi_master := $(addprefix rtl/, \
	qspi_master.v \
	qspi_phy_ice40_1x.v \
	qspi_phy_ice40_2x.v \
	qspi_phy_ice40_4x.v \
)

TESTBENCHES_qspi_master := \
	qspi_master_tb \
	$(NULL)

include $(NO2BUILD_DIR)/core-magic.mk
