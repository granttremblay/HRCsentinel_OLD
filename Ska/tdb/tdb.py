"""Ska.tdb: Access the Chandra Telemetry Database

:Author: Tom Aldcroft
:Copyright: 2012 Smithsonian Astrophysical Observatory
"""
import os
import re
import glob

import numpy as np
import six

__all__ = ['msids', 'tables', 'set_tdb_version', 'get_tdb_version',
           'TableView', 'MsidView']


SKA = os.environ.get('SKA', os.path.join(os.sep, 'proj', 'sot', 'ska'))

# Set None values for module globals that are set in set_tdb_version
TDB_VERSIONS = None
TDB_VERSION = None
DATA_DIR = None
tables = None
msids = None

# Tables with MSID column.  Might not be complete.
MSID_TABLES = ['tmsrment', 'tpc', 'tsc', 'tpp', 'tlmt', 'tcntr',
               'tsmpl', 'tloc']

TMSRMENT_COLS = """
                MSID
                TECHNICAL_NAME
                DATA_TYPE
                CALIBRATION_TYPE
                ENG_UNIT
                LOW_RAW_COUNT
                HIGH_RAW_COUNT
                TOTAL_LENGTH
                PROP
                COUNTER_MSID
                RANGE_MSID
                CALIBRATION_SWITCH_MSID
                CALIBRATION_DEFAULT_SET_NUM
                LIMIT_SWITCH_MSID
                LIMIT_DEFAULT_SET_NUM
                ES_SWITCH_MSID
                ES_DEFAULT_SET_NUM
                OWNER_ID
                DESCRIPTION
                EHS_HEADER_FLAG
                """.lower().split()


def set_tdb_version(version=None):
    """
    Set the version of the TDB which is used.

    :param version: TDB version (integer or None => latest)
    """
    global TDB_VERSION
    global TDB_VERSIONS
    global DATA_DIR
    global tables
    global msids
    version_dirs = glob.glob(os.path.join(SKA, 'data', 'Ska.tdb', 'p0??'))
    TDB_VERSIONS = sorted([int(os.path.basename(vdir)[2:]) for vdir in version_dirs])

    if version is None:
        if TDB_VERSIONS:
            version = TDB_VERSIONS[-1]
        else:
            version = 0  # Allow for package import / installation with no data
    elif version not in TDB_VERSIONS:
        raise ValueError('TDB version must be one of the following: {}'.format(TDB_VERSIONS))

    TDB_VERSION = version
    DATA_DIR = os.path.join(SKA, 'data', 'Ska.tdb', 'p{:03d}'.format(TDB_VERSION))
    tables = TableDict()
    msids = MsidView()


def get_tdb_version():
    """
    Get the version of the TDB which is used, e.g. 10.
    """
    return TDB_VERSION


class TableDict(dict):
    def __getitem__(self, item):
        if item not in self:
            try:
                filename = os.path.join(DATA_DIR, item + '.npy')
                self[item] = TableView(np.load(filename))
            except IOError:
                raise KeyError("Table {} not in TDB files (no file {})".format(item, filename))
        return dict.__getitem__(self, item)

    def keys(self):
        import glob
        files = glob.glob(os.path.join(DATA_DIR, '*.npy'))
        return [os.path.basename(x)[:-4] for x in files]


class TableView(object):
    """Access TDB tables directly.

    This class should be used through the module-level ``tables`` variable.
    The ``tables`` variable is a special dict object that returns a
    ``TableView`` object when you ask for a TDB table such as ``tmsrment``
    (MSID descriptions) or ``tsc`` (MSID state codes).

    For tables that have an MSID column you can filter on the MSID to see only
    entries for that MSID.  The MSID names are case-insensitive.

    Examples::

      from Ska.tdb import tables

      tables.keys()  # show all available tables
      tmsrment = tables['tmsrment']
      tmsrment  # show the table
      tmsrment.colnames  # column names for this table
      tmsrment['technical_name']
      tmsrment['tephin']  # only TEPHIN entries
      tables['tsc']['aoattqt4']  # State codes for AOATTQT4
      tables['tpp']['TEPHIN']  # Point pair for TEPHIN
    """
    def __init__(self, data):
        if six.PY2 or isinstance(data, np.void):
            # np.void case is when TableView is passed a table row, in which case
            # it has already been converted to string.
            self.data = data

        else:
            # Convert numpy bytes (S) to string (U) within structured array
            dtypes = []
            for name, typestr in data.dtype.descr:
                typestr = re.sub(r'S', 'U', typestr)
                dtypes.append((name, typestr))
            out = np.ndarray(len(data), dtype=dtypes)
            for name in data.dtype.names:
                # Note that numpy doesn't require explicit decode encoding to
                # be specified.
                out[name] = data[name]
            self.data = out

    def __getitem__(self, item):
        if isinstance(item, six.string_types):
            item = item.upper()
            if (item not in self.data.dtype.names and
                    'MSID' in self.data.dtype.names):
                ok = self.data['MSID'] == item
                new_data = self.data[ok]
                if len(new_data) == 1:
                    new_data = new_data[0]
                return TableView(new_data)

        return self.data[item]

    @property
    def colnames(self):
        return self.data.dtype.names

    def __repr__(self):
        return self.data.__repr__()

    def __len__(self):
        try:
            return len(self.data)
        except TypeError:
            return 1


class MsidView(object):
    """View TDB data related to a particular MSID.

    This class should be used through the module-level ``msids`` variable.
    This allows access to TDB table entries for the MSID (attributes starting
    with "T") and TDB ``tmsrment`` table columns (lower-case attributes).

    Examples::

      from Ska.tdb import msids
      msids.<TAB>  # See available attributes

      tephin = msids['tephin']
      tephin.<TAB>  # See available attributes
      tephin.Tmsrment  # MSID definition (description, tech name etc)
      tephin.Tpp  # Calibration point pair values
      tephin.Tsc  # No state codes so it returns None
      tephin.technical_name
      tephin.data_type

      msids['aopcadmd'].Tsc  # state codes
      msids['aopcadmd'].description  # description from tmsrment
    """
    def __init__(self, msid=None):
        self._msid = msid

        # If not done already set up class properties to access attributes
        if not hasattr(self.__class__, 'msid'):
            for attr in MSID_TABLES:
                setattr(self.__class__, attr.title(),
                        property(MsidView._get_table_func(attr)))
            for attr in TMSRMENT_COLS:
                setattr(self.__class__, attr,
                        property(MsidView._get_tmsrment_func(attr)))

    def find(self, *matches):
        """Find MSIDs with one or more ``matches`` in the ``msid``, ``description`` or
        ``technical_name``.

        Examples::

          >>> msids.find('tephin')
          [<MsidView msid="TEPHIN" technical_name="EPHIN SENSOR HOUSING TEMP">]

          >>> msids.find('aca', 'filter')
          [<MsidView msid="AOACIDPX" technical_name="ACA DATA PROCESSING DEFECTIVE PIXEL FILTER ENAB/DISA">,
           <MsidView msid="AOACIIRS" technical_name="ACA DATA PROCESSING IONIZING RADIATION FILTER ENAB/DISA">,
           <MsidView msid="AOACIMSS" technical_name="ACA DATA PROCESSING MULTIPLE STARS FILTER ENAB/DISA">,
           <MsidView msid="AOACISPX" technical_name="ACA DATA PROCESSING SATURATED PIXEL FILTER ENAB/DISA">]

        :param \*matches: one or more regular expression to match
        :returns: list of matching MSIDs as MsidView objects
        """
        ok = np.ones(len(msids.msid), dtype=bool)

        for match in matches:
            match_re = re.compile(match, re.IGNORECASE)
            ok0 = [match_re.search(x) is not None
                   for x in msids.msid]
            ok1 = [match_re.search(x) is not None
                   for x in msids.description]
            ok2 = [match_re.search(x) is not None
                   for x in msids.technical_name]
            ok &= np.array(ok0) | np.array(ok1) | np.array(ok2)

        return [msids[x] for x in tables['tmsrment']['MSID'][ok]]

    def __getitem__(self, item):
        if item.upper() in tables['tmsrment']['MSID']:
            return MsidView(item)
        else:
            raise KeyError('No MSID {} in TDB'.format(item))

    @staticmethod
    def _get_table_func(tablename):
        def _func(self):
            if self._msid:
                val = tables[tablename][self._msid]
                if len(val) == 0:
                    val = None
                return val
            else:
                return tables[tablename]
        return _func

    @staticmethod
    def _get_tmsrment_func(tmsrment_col):
        def _func(self):
            tablename = 'tmsrment'
            if self._msid:
                val = tables[tablename][self._msid][tmsrment_col]
                return val
            else:
                return tables[tablename][tmsrment_col]
        return _func

    def __repr__(self):
        if self._msid:
            return '<MsidView msid="{}" technical_name="{}">'.format(
                self.msid, self.technical_name)
        else:
            return object.__repr__(self)


set_tdb_version()  # Choose the most recent version
