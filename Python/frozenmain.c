
/* Python interpreter main program for frozen scripts */

#include "Python.h"
#include "pycore_runtime.h"  // _PyRuntime_Initialize()
#include <locale.h>

#ifdef MS_WINDOWS
extern void PyWinFreeze_ExeInit(void);
extern void PyWinFreeze_ExeTerm(void);
extern int PyInitFrozenExtensions(void);
#endif

/* Main program */

int
Py_FrozenMain(int argc, char **argv)
{
    PyStatus status = _PyRuntime_Initialize();
    if (PyStatus_Exception(status)) {
        Py_ExitStatusException(status);
    }

    const char *p;
    int i, n, sts = 1;
    int inspect = 0;
    int unbuffered = 0;
    char *oldloc = NULL;
    wchar_t **argv_copy = NULL;
    /* We need a second copies, as Python might modify the first one. */
    wchar_t **argv_copy2 = NULL;

    if (argc > 0) {
        argv_copy = PyMem_RawMalloc(sizeof(wchar_t*) * argc);
        argv_copy2 = PyMem_RawMalloc(sizeof(wchar_t*) * argc);
        if (!argv_copy || !argv_copy2) {
#if !TARGET_OS_IPHONE
            fprintf(stderr, "out of memory\n");
#else
            fprintf(thread_stderr, "out of memory\n");
#endif
            goto error;
        }
    }

    PyConfig config;
    PyConfig_InitPythonConfig(&config);
    config.pathconfig_warnings = 0;   /* Suppress errors from getpath.c */

    if ((p = Py_GETENV("PYTHONINSPECT")) && *p != '\0')
        inspect = 1;
    if ((p = Py_GETENV("PYTHONUNBUFFERED")) && *p != '\0')
        unbuffered = 1;

#if !TARGET_OS_IPHONE
    if (unbuffered) {
        setbuf(stdin, (char *)NULL);
        setbuf(stdout, (char *)NULL);
        setbuf(stderr, (char *)NULL);
    }
#else
    if (unbuffered) {
        setbuf(thread_stdin, (char *)NULL);
        setbuf(thread_stdout, (char *)NULL);
        setbuf(thread_stderr, (char *)NULL);
    }
#endif

    oldloc = _PyMem_RawStrdup(setlocale(LC_ALL, NULL));
    if (!oldloc) {
#if !TARGET_OS_IPHONE
        fprintf(stderr, "out of memory\n");
#else
        fprintf(thread_stderr, "out of memory\n");
#endif
        goto error;
    }

    setlocale(LC_ALL, "");
    for (i = 0; i < argc; i++) {
        argv_copy[i] = Py_DecodeLocale(argv[i], NULL);
        argv_copy2[i] = argv_copy[i];
        if (!argv_copy[i]) {
#if !TARGET_OS_IPHONE
            fprintf(stderr, "Unable to decode the command line argument #%i\n",
#else
            fprintf(thread_stderr, "Unable to decode the command line argument #%i\n",
#endif
                            i + 1);
            argc = i;
            goto error;
        }
    }
    setlocale(LC_ALL, oldloc);
    PyMem_RawFree(oldloc);
    oldloc = NULL;

#ifdef MS_WINDOWS
    PyInitFrozenExtensions();
#endif /* MS_WINDOWS */
    if (argc >= 1)
        Py_SetProgramName(argv_copy[0]);

    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    if (PyStatus_Exception(status)) {
        Py_ExitStatusException(status);
    }

#ifdef MS_WINDOWS
    PyWinFreeze_ExeInit();
#endif

    if (Py_VerboseFlag)
#if !TARGET_OS_IPHONE
        fprintf(stderr, "Python %s\n%s\n",
#else
        fprintf(thread_stderr, "Python %s\n%s\n",
#endif
            Py_GetVersion(), Py_GetCopyright());

    PySys_SetArgv(argc, argv_copy);

    n = PyImport_ImportFrozenModule("__main__");
    if (n == 0)
        Py_FatalError("the __main__ module is not frozen");
    if (n < 0) {
        PyErr_Print();
        sts = 1;
    }
    else
        sts = 0;

#if !TARGET_OS_IPHONE
    if (inspect && isatty((int)fileno(stdin)))
        sts = PyRun_AnyFile(stdin, "<stdin>") != 0;
#else
    if (inspect && ios_isatty((int)fileno(stdin)))
        sts = PyRun_AnyFile(thread_stdin, "<stdin>") != 0;
#endif

#ifdef MS_WINDOWS
    PyWinFreeze_ExeTerm();
#endif
    if (Py_FinalizeEx() < 0) {
        sts = 120;
    }

error:
    PyMem_RawFree(argv_copy);
    if (argv_copy2) {
        for (i = 0; i < argc; i++)
            PyMem_RawFree(argv_copy2[i]);
        PyMem_RawFree(argv_copy2);
    }
    PyMem_RawFree(oldloc);
    return sts;
}
