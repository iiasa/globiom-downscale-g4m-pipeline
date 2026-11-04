#include "tableData.h"

// default constructor
tableData::tableData()
{
	descr = MDT();
	N = descr.getN();
}

// constructor
tableData::tableData(string fileNameGdc)
{
	ifstream f;
	f.open(fileNameGdc.c_str(), ios::in | ios::binary);
	if (f.is_open())
	{
		// Reading dimensions info:
		int nDims;
		f.read(reinterpret_cast<char *>(&nDims), sizeof(int));
		INV_BYTE_ORDER(nDims);
		int_vector_t dimCardinals;
		dimCardinals.resize(4);
		for (int i = 0; i < nDims; i++)
		{
			int tmp;
			f.read(reinterpret_cast<char *>(&tmp), sizeof(int));
			INV_BYTE_ORDER(tmp);
			dimCardinals[i] = tmp;
		}
		// Reading *.gdt file
		string fileNameGdt;
		if(fileNameGdc.find_last_of(".") != std::string::npos)
		{
			fileNameGdt = fileNameGdc.substr(0, fileNameGdc.find_last_of(".") + 1) + "gdt";
		}
		else
		{
			// TODO: add error
		}
		descr = MDT(fileNameGdt, dimCardinals);
		// Number of non-zero records in the dataset
		int numRecords;
		f.read(reinterpret_cast<char *>(&numRecords), sizeof(int));
		INV_BYTE_ORDER(numRecords);
		// Reading data to buffers (still little endian)
		long long * hashTable = new long long [numRecords];
		f.read(reinterpret_cast<char *>(hashTable), sizeof(long long) * numRecords);
		float * valuesTable = new float [numRecords];
		f.read(reinterpret_cast<char *>(valuesTable), sizeof(float) * numRecords);
		// Processing buffers
		for (int i = 0; i < numRecords; i++)
		{
			INV_BYTE_ORDER(valuesTable[i]);
			INV_BYTE_ORDER(hashTable[i]);
			data.insert(make_pair(hashTable[i], valuesTable[i]));
		}
		cout << "Successfully read table from binary file: " << fileNameGdc << endl;
	}
	else
	{
		cout << "Unable to read file! : \t" << fileNameGdc << endl;
		// TODO: add error
	}
	// TODO: add execution OK
}

// destructor
tableData::~tableData()
{
/*  map<int, float_vector_t>::iterator it = data.begin();
  while (it != data.end()) {
    delete it->second;
    it++;
  }*/
}

//================
// Class methods:
//================

void tableData::insert(float val, str_vector_t point)
{
	if (val != 0)
	{
		data.insert(make_pair(descr.getHash(point), val));
	}
}

void tableData::insert(float val, int_vector_t point)
{
	if (val != 0)
	{
		data.insert(make_pair(descr.getHashByCoords(point), val));
	}
}

void tableData::update(float val, str_vector_t point)
{
	if (val != 0)
	{
		long long card = descr.getHash(point);
		data.erase(card);
		data.insert(make_pair(card, val));
	}
}

void tableData::rename(string name)
{
	descr.paramName = name;
}

void tableData::renameDims(str_vector_t vec)
{
	descr.dimNames = vec;
}

void tableData::addDim(string dimName, set<string> elements)
{
	str_vector_t tmp;
	set<string>::iterator it = elements.begin();
	while(it != elements.end())
	{
		tmp.push_back(*it);
		it++;
	}
	descr.addDim(dimName,tmp);
}

void tableData::addDim(string dimName, set<int> elements)
{
	str_vector_t tmp;
	set<int>::iterator it = elements.begin();
	while(it != elements.end())
	{
		tmp.push_back(IntToStr(*it));
		it++;
	}
	descr.addDim(dimName,tmp);
}

void tableData::addDim(string dimName, string element)
{
	str_vector_t tmp;
	tmp.push_back(element);
	descr.addDim(dimName,tmp);
}

void tableData::updateDimEl(string dimName, int posEl, string element)
{
    descr.updateDimEl(dimName, posEl, element);
}


void tableData::clear()
{
	data.clear();
	descr.clear();
}

int tableData::append(tableData & another, int dim)
{
	if (descr.nDims != another.descr.nDims)
	{
		printf("Error! Table dimensions must agree. This nDims - %d, another nDims - %d\n", descr.nDims, another.descr.nDims);
		return -1; // dimensions must agree
	}
	for (int i = 0; i < descr.nDims; i++)
	{
		if ((i != dim) && (descr.dimCardinals[i] != another.descr.dimCardinals[i]))
		{
			printf("Error! Table dimensions must agree. Dim: %d, this size - %d, another size - %d\n", i, 
				descr.dimCardinals[i], another.descr.dimCardinals[i]);
			return -1; // dimensions must agree
		}
	}
	// TODO: add validation of dimensions' elements

	// Storing initial size of dimension by which we concatenate tables
	int thisDimSize = descr.dimCardinals[dim];
	// Make a copy of own data map
	map<long long, float> dataCopy = data;
//	map<long, float> dataCopy = data;
	MDT descrCopy = descr;
	// Appending data to MDT-description
	string dimName = descr.dimNames[dim];
	for (int i = 0; i < another.descr.dimCardinals[dim]; i++)
	{
		descr.addDimEl(dimName, another.descr.dimElements[dim][i]);
	}
	// Clear own data
	data.clear();
	// Fill new merged data with own data, updating hash table
	map<long long, float>::iterator it;
//	map<long , float>::iterator it;
	for (it = dataCopy.begin(); it != dataCopy.end(); it++)
	{
		int_vector_t coords = descrCopy.getCoordsByHash(it->first);
		insert(it->second, coords);
	}
	// Fill new merged data with another's data, updating hash table
	for (it = another.data.begin(); it != another.data.end(); it++)
	{
		int_vector_t coords = another.descr.getCoordsByHash(it->first);
		coords[dim] += thisDimSize;
		insert(it->second, coords);
	}
	return 0;
}

bool tableData::SaveToFile(string outDir, string fileName)
{
	//****************************
	//**** Writimg *.GDC file ****
	//****************************
	if (data.size() == 0)
	{
		cout << "ERROR! Attempt to write empty data." << endl;
		return false;
	}
	fileName = outDir + pathSeparator + fileName;
	string fileNameTmp = fileName + ".gdc";
	ofstream f;
	f.open(fileNameTmp.c_str(), ios::out | ios::binary);
	if (f.is_open())
	{
		// Writing info about dimensions:
		int tmp_int = descr.getNDims();
		INV_BYTE_ORDER(tmp_int);
		f.write(reinterpret_cast<char *>(&tmp_int), sizeof(int));
		for (int i = 0; i < descr.nDims; i++)
		{
			tmp_int = descr.dimCardinals[i];
			INV_BYTE_ORDER(tmp_int);
			f.write(reinterpret_cast<char *>(&tmp_int), sizeof(int));
		}
		// Writing hash data:
		tmp_int = data.size();
		int numVal = tmp_int;
		long long * vl = new long long [numVal];
		float * vf = new float [numVal];
		INV_BYTE_ORDER(tmp_int);
		f.write(reinterpret_cast<char *>(&tmp_int), sizeof(int));
		int i = 0;
		map<long long, float>::iterator it = data.begin();
		while (it != data.end())
		{
			long long tmp_long = it->first;
			INV_BYTE_ORDER(tmp_long);
			vl[i] = tmp_long;
			float tmp_float = it->second;
			INV_BYTE_ORDER(tmp_float);
			vf[i] = tmp_float;
			i++;
			it++;
		}
		f.write(reinterpret_cast<char *>(vl), sizeof(long long) * numVal);
		f.write(reinterpret_cast<char *>(vf), sizeof(float) * numVal);
		delete []vl;
		delete []vf;
		f.close();
		cout << "Successfully written to binary file: " << fileNameTmp << endl;
	}
	else
	{
		cout << "Unable to save to file! : \t" << fileNameTmp << endl;
		return false;
	}
	//****************************
	//**** Writimg *.GDT file ****
	//****************************
	descr.SaveToFile(fileName + ".gdt", "TABLE");
	return true;
}

bool tableData::SaveToFileCSV(string outDir, string fileName, bool FirstLine)
{
	//****************************
	//**** Writimg *.csv file ****
	//****************************
	if (data.size() == 0)
	{
		cout << "ERROR! Attempt to write empty data." << endl;
		return false;
	}
	fileName = outDir + pathSeparator + fileName;
	string fileNameTmp = fileName + ".csv";
	ofstream f;
	f.open(fileNameTmp.c_str(), std::ios::app);
	if (f.is_open())
	{
		// Writing info about dimensions:
//	f<<descr.dimNames[2]<<","<<descr.dimNames[0]<<","<<descr.dimNames[3];
	if (FirstLine == true) {
		f<<""<<","<<""<<","<<"";
		//cout<<descr.dimNames[2]<<","<<descr.dimNames[0]<<","<<descr.dimNames[3];
			for (int i=0;i<descr.dimCardinals[1];i++) {f<<","<<descr.dimElements[1][i];}
		//for (int i=0;i<descr.dimCardinals[1];i++) {cout<<","<<descr.dimElements[1][i];}
			f<<endl;
	}
//cout<<endl;
	for (int country_i = 0; country_i<descr.dimCardinals[2];country_i++)
		{
		for (int scenario_i = 0;scenario_i<descr.dimCardinals[0];scenario_i++)
			{
			for (int parameter_i = 0;parameter_i<descr.dimCardinals[3];parameter_i++) 
				{
				f<<descr.dimElements[2][country_i]<<","<<descr.dimElements[0][scenario_i]<<","<<descr.dimElements[3][parameter_i];
//cout<<descr.dimElements[2][country_i]<<","<<descr.dimElements[0][scenario_i]<<","<<descr.dimElements[3][parameter_i];
				for (int year_i = 0;year_i<descr.dimCardinals[1];year_i++) 
					{
					
					MDT::int_vector_t currentElem_coords;		
					currentElem_coords.resize(4);
					currentElem_coords[0] = scenario_i;			
					currentElem_coords[1] = year_i;				
					currentElem_coords[2] = country_i;			
					currentElem_coords[3] = parameter_i;		
					long long currentElem_hash = descr.getHashByCoords(currentElem_coords);

					MDT::str_vector_t currentElem_coords_str;	
					currentElem_coords_str.resize(4);
					currentElem_coords_str[0] = descr.dimElements[0][scenario_i];
					currentElem_coords_str[1] = descr.dimElements[1][year_i];
					currentElem_coords_str[2] = descr.dimElements[2][country_i];
					currentElem_coords_str[3] = descr.dimElements[3][parameter_i];
					long long currentElem_hash_1 = descr.getHash(currentElem_coords_str);

if (currentElem_hash!=currentElem_hash_1) cout<< "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"; // Testing to decide which one to use

					if (data.count(currentElem_hash_1)>0)
						{
				    f<<","<<data.find(currentElem_hash)->second;

//cout<<","<<data.find(currentElem_hash)->second;
//cout<<","<<data.find(currentElem_hash_1)->second;
						}else
						{f<<","<<0;
//cout<<","<<0;
							}
					}
				f<<endl;
//cout<<endl;
				}
			}
		}

		f.close();
		cout << "Successfully written to binary file: " << fileNameTmp << endl;
	}
	else
	{
		cout << "Unable to save to file! : \t" << fileNameTmp << endl;
		return false;
	}
	return true;
}
