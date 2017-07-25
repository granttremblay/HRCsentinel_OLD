from .. import msids, tables, set_tdb_version, get_tdb_version

# Set to fixed version for regression testing
TDB_VERSION = 14
set_tdb_version(TDB_VERSION)

tmsrment_colnames = (
    'MSID', 'TECHNICAL_NAME', 'DATA_TYPE', 'CALIBRATION_TYPE', 'ENG_UNIT', 'LOW_RAW_COUNT',
    'HIGH_RAW_COUNT', 'TOTAL_LENGTH', 'PROP', 'COUNTER_MSID', 'RANGE_MSID',
    'CALIBRATION_SWITCH_MSID', 'CALIBRATION_DEFAULT_SET_NUM', 'LIMIT_SWITCH_MSID',
    'LIMIT_DEFAULT_SET_NUM', 'ES_SWITCH_MSID', 'ES_DEFAULT_SET_NUM', 'OWNER_ID',
    'DESCRIPTION', 'EHS_HEADER_FLAG')


def test_msids():
    tephin = msids['tephin']
    assert tephin.Tmsrment.colnames == tmsrment_colnames
    vals = list(tephin.Tmsrment.data)
    assert vals == ['TEPHIN', 'EPHIN SENSOR HOUSING TEMP', 'IUNS', 'PP', 'DEGF', 0, 255, 8,
                    'N', '0', '0', '0', 1, '0', 1, '0', 0, 'THM', 'LR/15/PA/2', 'U']

    assert tephin.Tpp.data.dtype.names == ('MSID', 'CALIBRATION_SET_NUM', 'SEQUENCE_NUM',
                                           'RAW_COUNT', 'ENG_UNIT_VALUE')

    vals = msids.find('teph')
    assert [v.msid for v in vals] == ['TEPHIN', 'TEPHTRP1', 'TEPHTRP2', 'TEPHTRR1', 'TEPHTRR2']


def test_find():
    ms = msids.find('tephin')
    assert len(ms) == 1
    assert ms[0].msid == 'TEPHIN'

    ms = msids.find('aca', 'filter')
    assert len(ms) == 4
    assert set([m.msid for m in ms]) == set(["AOACIDPX", "AOACIIRS", "AOACIMSS", "AOACISPX"])


def test_tables():
    assert sorted(tables.keys()) == ['tcntr', 'tes', 'tlmt', 'tloc', 'tmsrment', 'towner', 'tpc',
                                     'tpp', 'tsc', 'tsmpl', 'tstream', 'ttdm', 'ttdm_fmt']

    tm = tables['tmsrment']
    assert tm.colnames == tmsrment_colnames


def test_version():
    assert list(msids['tephin'].Tlmt) == ['TEPHIN', 1, 10.0, 161.0, 5.0, 999.0, 0, 5, 'A']
    set_tdb_version(8)
    assert get_tdb_version() == 8
    assert list(msids['tephin'].Tlmt) == ['TEPHIN', 1, 10.0, 81.0, 5.0, 86.0, 0, 5, 'A']
    set_tdb_version(TDB_VERSION)
