//  Name:         tableData class
//  Author:       Andriy Bun
//  Date:         13.11.09
//  Modified:     11.01.10 (Andriy Bun)
//  Description:  Class for storing and producing data for viewing with
//                GDagaView Software. Is a friend class for MDT class.

#ifndef TABLEDATA_H_
#define TABLEDATA_H_

#include <map>
#include <set>
#include <vector>
#include <fstream>
#include <string>
#include <cmath>

#include "common.h"
#include "endianness.cpp"
#include "IntToStr.h"
#include "MDT.cpp"


using namespace std;

class tableData
{
private:
	typedef vector<string> str_vector_t;
	typedef vector<int> int_vector_t;
	map<long long, float> data;
	MDT descr;
	long long N;                           // Number of data records per simulation unit
public:
	tableData();
	tableData(string fileNameGdc);
	~tableData();
	// Inserts a value "val" corresponding to a vector of string coordinates "point" into the list.
	void insert(float val, str_vector_t point);
	// Inserts a value "val" corresponding to a vector of integer coordinates "point" into the list.
	void insert(float val, int_vector_t point);
	// Updates a value "val" corresponding to a vector of coordinates "point" into the list.
	void update(float val, str_vector_t point);
	// Rename dataset:
	void rename(string name);
	// Rename dimensions of the dataset:
	void renameDims(str_vector_t vec);
	// Add new dimension:
	void addDim(string dimName, set<string> elements);
	void addDim(string dimName, set<int> elements);
	void addDim(string dimName, string element);
	void updateDimEl(string dimName, int posEl, string element);
	// Clearing object
	void clear();
	// Append table by one of the dimensions
	int append(tableData & another, int dim);
	// Writing object to files *.GDT and *.GDC files
	bool SaveToFile(string outDir, string fileName);
	bool SaveToFileCSV(string outDir, string fileName, bool FirstLine); //MG: 18072018: Writing to csv file. Dimensions: Country, Scenario, Parameter v.s. years
};

#endif
