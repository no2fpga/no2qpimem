CORE := no2qpimem

DEPS_no2qpimem := no2misc no2ice40

RTL_SRCS_no2qpimem := $(addprefix rtl/, \
	qpi_memctrl.v \
	qpi_phy_ice40_1x.v \
	qpi_phy_ice40_2x.v \
	qpi_phy_ice40_4x.v \
)

TESTBENCHES_no2qpimem := \
	qpi_memctrl_tb \
	$(NULL)

include $(NO2BUILD_DIR)/core-magic.mk
